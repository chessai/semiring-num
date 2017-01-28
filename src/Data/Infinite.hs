{-# LANGUAGE DefaultSignatures   #-}
{-# LANGUAGE DeriveFoldable      #-}
{-# LANGUAGE DeriveFunctor       #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE DeriveTraversable   #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Data.Infinite
  ( HasPositiveInfinity(..)
  , HasNegativeInfinity(..)
  , NegativeInfinite(..)
  , PositiveInfinite(..)
  , Infinite(..)
  ) where

import           Foreign.C.Types     (CDouble, CFloat)

import           Control.Applicative (liftA2)
import           Data.Typeable       (Typeable)
import           GHC.Generics        (Generic, Generic1)

import           Data.Word           (Word8)
import           Foreign.Ptr         (Ptr, castPtr)
import           Foreign.Storable    (Storable, alignment, peek, peekByteOff,
                                      poke, pokeByteOff, sizeOf)

import           Data.Coerce
import           Data.Monoid

class HasPositiveInfinity a where
  positiveInfinity :: a
  default positiveInfinity :: RealFloat a => a
  positiveInfinity = 1/0

class HasNegativeInfinity a where
  negativeInfinity :: a
  default negativeInfinity :: RealFloat a => a
  negativeInfinity = negate (1/0)

instance HasPositiveInfinity Double
instance HasNegativeInfinity Double
instance HasPositiveInfinity Float
instance HasNegativeInfinity Float
instance HasPositiveInfinity CDouble
instance HasNegativeInfinity CDouble
instance HasPositiveInfinity CFloat
instance HasNegativeInfinity CFloat

data NegativeInfinite a
  = NegativeInfinity
  | NegFinite !a
  deriving (Eq, Ord, Read, Show, Generic, Generic1, Typeable, Functor
           ,Foldable, Traversable)

data PositiveInfinite a
  = PosFinite !a
  | PositiveInfinity
  deriving (Eq, Ord, Read, Show, Generic, Generic1, Typeable, Functor
           ,Foldable, Traversable)

instance Applicative NegativeInfinite where
  pure = NegFinite
  {-# INLINE pure #-}
  NegFinite f <*> NegFinite x = NegFinite (f x)
  _ <*> _ = NegativeInfinity
  {-# INLINE (<*>) #-}

instance Applicative PositiveInfinite where
  pure = PosFinite
  {-# INLINE pure #-}
  PosFinite f <*> PosFinite x = PosFinite (f x)
  _ <*> _ = PositiveInfinity
  {-# INLINE (<*>) #-}

data Infinite a
  = Negative
  | Finite !a
  | Positive
  deriving (Eq, Ord, Read, Show, Generic, Generic1, Typeable, Functor
           ,Foldable, Traversable)

instance Applicative Infinite where
  pure = Finite
  {-# INLINE pure #-}
  Finite f <*> Finite x = Finite (f x)
  Negative <*> Negative = Positive
  Negative <*> _ = Negative
  _ <*> Negative = Negative
  _ <*> _ = Positive
  {-# INLINE (<*>) #-}

instance Bounded a => Bounded (NegativeInfinite a) where
  {-# INLINE minBound #-}
  {-# INLINE maxBound #-}
  minBound = NegativeInfinity
  maxBound = pure maxBound

instance Bounded a => Bounded (PositiveInfinite a) where
  {-# INLINE minBound #-}
  {-# INLINE maxBound #-}
  minBound = pure minBound
  maxBound = PositiveInfinity

instance Bounded (Infinite a) where
  {-# INLINE minBound #-}
  {-# INLINE maxBound #-}
  minBound = Negative
  maxBound = Positive

instance HasNegativeInfinity (NegativeInfinite a) where
  {-# INLINE negativeInfinity #-}
  negativeInfinity = NegativeInfinity

instance HasPositiveInfinity (PositiveInfinite a) where
  {-# INLINE positiveInfinity #-}
  positiveInfinity = PositiveInfinity

instance HasNegativeInfinity (Infinite a) where
  {-# INLINE negativeInfinity #-}
  negativeInfinity = Negative

instance HasPositiveInfinity (Infinite a) where
  {-# INLINE positiveInfinity #-}
  positiveInfinity = Positive

instance (Enum a, Bounded a, Eq a) => Enum (NegativeInfinite a) where
  succ = foldr (const . pure . succ) (pure minBound)
  pred NegativeInfinity = error "Predecessor of negative infinity"
  pred (NegFinite x) | x == minBound = NegativeInfinity
                     | otherwise = NegFinite (pred x)
  toEnum 0 = NegativeInfinity
  toEnum n = NegFinite (toEnum (n-1))
  fromEnum = foldr (const . succ . fromEnum) 0
  enumFrom NegativeInfinity = NegativeInfinity : map pure [minBound..]
  enumFrom (NegFinite x)    = map pure [x..]

maxBoundOf :: Bounded a => f a -> a
maxBoundOf _ = maxBound

instance (Enum a, Bounded a, Eq a) => Enum (PositiveInfinite a) where
  pred = foldr (const . pure . pred) (pure maxBound)
  succ PositiveInfinity = error "Successor of positive infinity"
  succ (PosFinite x) | x == maxBound = PositiveInfinity
                     | otherwise = PosFinite (succ x)
  toEnum n
    | n == toEnum (maxBoundOf PositiveInfinity) + 1 = PositiveInfinity
    | otherwise = PosFinite (toEnum n)
  fromEnum p@PositiveInfinity = fromEnum (maxBoundOf p) + 1
  fromEnum (PosFinite x)      = fromEnum x
  enumFrom PositiveInfinity = [PositiveInfinity]
  enumFrom (PosFinite x)    = map pure [x..] ++ [PositiveInfinity]

instance (Enum a, Bounded a, Eq a) => Enum (Infinite a) where
  pred Negative = error "Predecessor of negative infinity"
  pred Positive = Finite maxBound
  pred (Finite x) | x == minBound = Negative
                  | otherwise = Finite (pred x)
  succ Negative = Finite minBound
  succ Positive = error "Successor of positive infinity"
  succ (Finite x) | x == maxBound = Positive
                  | otherwise = Finite (succ x)
  toEnum 0 = Negative
  toEnum n | n == toEnum (maxBoundOf Positive) + 2 = Positive
           | otherwise = Finite (toEnum (n-1))
  fromEnum Negative   = 0
  fromEnum (Finite x) = fromEnum x + 1
  fromEnum p@Positive = fromEnum (maxBoundOf p) + 1
  enumFrom Positive   = [Positive]
  enumFrom Negative   = Negative : map pure [minBound..] ++ [Positive]
  enumFrom (Finite x) = map pure (enumFrom x) ++ [Positive]

instance Monoid a => Monoid (NegativeInfinite a) where
  {-# INLINE mempty #-}
  {-# INLINE mappend #-}
  mempty = pure mempty
  mappend = liftA2 mappend

instance Monoid a => Monoid (PositiveInfinite a) where
  {-# INLINE mempty #-}
  {-# INLINE mappend #-}
  mempty = pure mempty
  mappend = liftA2 mappend

instance Monoid a => Monoid (Infinite a) where
  {-# INLINE mempty #-}
  {-# INLINE mappend #-}
  mempty = pure mempty
  Negative `mappend` Positive = pure mempty
  Positive `mappend` Negative = pure mempty
  Negative `mappend` _ = Negative
  Positive `mappend` _ = Positive
  Finite x `mappend` Finite y = pure (x `mappend` y)
  _ `mappend` y = y

instance Num a => Num (NegativeInfinite a) where
  fromInteger = pure . fromInteger
  (+) = liftA2 (+)
  (*) = liftA2 (*)
  abs = fmap abs
  signum = foldr (const . pure . signum) (-1)
  (-) = liftA2 (-)

instance Num a => Num (PositiveInfinite a) where
  fromInteger = pure . fromInteger
  (+) = liftA2 (+)
  (*) = liftA2 (*)
  abs = fmap abs
  signum = foldr (const . pure . signum) (-1)
  (-) = liftA2 (-)

type CoerceBinary a b = (a -> a -> a) -> (b -> b -> b)

instance Num a => Num (Infinite a) where
  fromInteger = Finite . fromInteger
  (+) = (coerce :: CoerceBinary (Infinite (Sum a)) (Infinite a)) mappend
  (*) = liftA2 (*)
  signum Positive   = 1
  signum Negative   = -1
  signum (Finite x) = Finite (signum x)
  negate Positive   = Negative
  negate Negative   = Positive
  negate (Finite x) = Finite (negate x)
  abs Negative = Positive
  abs x = fmap abs x

-- Adapted from https://www.schoolofhaskell.com/user/snoyberg/random-code-snippets/storable-instance-of-maybe
instance Storable a => Storable (NegativeInfinite a) where
    sizeOf x = sizeOf (strip x) + 1
    alignment x = alignment (strip x)
    peek ptr = (peekByteOff ptr . sizeOf . strip . stripPtr) ptr >>= \case
      (1 :: Word8) -> NegFinite <$> peek (stripFPtr ptr)
      _ -> pure NegativeInfinity
    poke ptr NegativeInfinity
      = pokeByteOff ptr ((sizeOf . strip . stripPtr) ptr) (0 :: Word8)
    poke ptr (NegFinite a)
      = poke (stripFPtr ptr) a
     *> pokeByteOff ptr (sizeOf a) (1 :: Word8)

instance Storable a => Storable (PositiveInfinite a) where
    sizeOf x = sizeOf (strip x) + 1
    alignment x = alignment (strip x)
    peek ptr = (peekByteOff ptr . sizeOf . strip . stripPtr) ptr >>= \case
      (1 :: Word8) -> PosFinite <$> peek (stripFPtr ptr)
      _ -> pure PositiveInfinity
    poke ptr PositiveInfinity
      = pokeByteOff ptr ((sizeOf . strip . stripPtr) ptr) (0 :: Word8)
    poke ptr (PosFinite a)
      = poke (stripFPtr ptr) a
     *> pokeByteOff ptr (sizeOf a) (1 :: Word8)

instance Storable a => Storable (Infinite a) where
    sizeOf x = sizeOf (strip x) + 1
    alignment x = alignment (strip x)
    peek ptr = (peekByteOff ptr . sizeOf . strip . stripPtr) ptr >>= \case
      (0 :: Word8) -> Finite <$> peek (stripFPtr ptr)
      1 -> pure Negative
      _ -> pure Positive
    poke ptr Positive
      = pokeByteOff ptr ((sizeOf . strip . stripPtr) ptr) (2 :: Word8)
    poke ptr Negative
      = pokeByteOff ptr ((sizeOf . strip . stripPtr) ptr) (1 :: Word8)
    poke ptr (Finite a)
      = poke (stripFPtr ptr) a
     *> pokeByteOff ptr (sizeOf a) (1 :: Word8)

strip :: f a -> a
strip _ = error "strip"

stripFPtr :: Ptr (f a) -> Ptr a
stripFPtr = castPtr

stripPtr :: Ptr a -> a
stripPtr _ = error "stripPtr"