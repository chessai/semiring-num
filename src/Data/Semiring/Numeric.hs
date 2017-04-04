{-# LANGUAGE DeriveFoldable             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DeriveTraversable          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

{-|
Module: Data.Semiring.Numeric
Description: Some interesting numeric semirings
License: MIT
Maintainer: mail@doisinkidney.com
Stability: experimental
-}
module Data.Semiring.Numeric
  ( Bottleneck(..)
  , Division(..)
  , Łukasiewicz(..)
  , Viterbi(..)
  , PosFrac(..)
  , PosInt(..)
  ) where

import           Data.Coerce
import           Data.Semiring
import           GHC.Generics

import           Data.Typeable    (Typeable)
import           Foreign.Storable (Storable)

type WrapBinary f a = (a -> a -> a) -> f a -> f a -> f a

-- | Useful for some constraint problems.
--
-- @('<+>') = 'max'
--('<.>') = 'min'
--'zero'  = 'minBound'
--'one'   = 'maxBound'@
newtype Bottleneck a = Bottleneck
  { getBottleneck :: a
  } deriving (Eq, Ord, Read, Show, Bounded, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable)

instance (Bounded a, Ord a) => Semiring (Bottleneck a) where
  (<+>) = (coerce :: WrapBinary Bottleneck a) max
  (<.>) = (coerce :: WrapBinary Bottleneck a) min
  zero = Bottleneck minBound
  one  = Bottleneck maxBound
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

instance (Bounded a, Ord a) => DetectableZero (Bottleneck a) where
  isZero = (zero==)

-- | Positive numbers only.
--
-- @('<+>') = 'gcd'
--('<.>') = 'lcm'
--'zero'  = 'zero'
--'one'   = 'one'@
newtype Division a = Division
  { getDivision :: a
  } deriving (Eq, Ord, Read, Show, Bounded, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable,DetectableZero)

-- | Only expects positive numbers
instance (Integral a, Semiring a) => Semiring (Division a) where
  (<+>) = (coerce :: WrapBinary Division a) gcd
  (<.>) = (coerce :: WrapBinary Division a) lcm
  zero = Division zero
  one = Division one
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

-- | <https://en.wikipedia.org/wiki/Semiring#cite_ref-droste_14-0 Wikipedia>
-- has some information on this. Also
-- <http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.304.6152&rep=rep1&type=pdf this>
-- paper.
--
-- @('<+>')   = 'max'
--x '<.>' y = 'max' 0 (x '+' y '-' 1)
--'zero'    = 'zero'
--'one'     = 'one'@
newtype Łukasiewicz a = Łukasiewicz
  { getŁukasiewicz :: a
  } deriving (Eq, Ord, Read, Show, Bounded, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable)

instance (Ord a, Num a) => Semiring (Łukasiewicz a) where
  (<+>) = (coerce :: WrapBinary Łukasiewicz a) max
  (<.>) = (coerce :: WrapBinary Łukasiewicz a) (\x y -> max 0 (x + y - 1))
  zero = Łukasiewicz 0
  one  = Łukasiewicz 1
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

instance (Ord a, Num a) => DetectableZero (Łukasiewicz a) where
  isZero = (zero==)

-- | <https://en.wikipedia.org/wiki/Semiring#cite_ref-droste_14-0 Wikipedia>
-- has some information on this. Also
-- <http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.304.6152&rep=rep1&type=pdf this>
-- paper. Apparently used for probabilistic parsing.
--
-- @('<+>') = 'max'
--('<.>') = ('<.>')
--'zero'  = 'zero'
--'one'   = 'one'@
newtype Viterbi a = Viterbi
  { getViterbi :: a
  } deriving (Eq, Ord, Read, Show, Bounded, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable,DetectableZero)

instance (Ord a, Semiring a) => Semiring (Viterbi a) where
  (<+>) = (coerce :: WrapBinary Viterbi a) max
  (<.>) = (coerce :: WrapBinary Viterbi a) (<.>)
  zero = Viterbi zero
  one  = Viterbi one
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

-- | Adds a star operation to fractional types.
--
-- @('<+>')  = ('<+>')
--('<.>')  = ('<.>')
--'zero'   = 'zero'
--'one'    = 'one'
--'star' x = if x < 1 then 1 / (1 - x) else 'positiveInfinity'@
newtype PosFrac a = PosFrac
  { getPosFrac :: a
  } deriving (Eq, Ord, Read, Show, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable)

instance (Bounded a, Semiring a) => Bounded (PosFrac a) where
  minBound = PosFrac zero
  maxBound = PosFrac maxBound

instance Semiring a => Semiring (PosFrac a) where
  (<+>) = (coerce :: WrapBinary PosFrac a) (<+>)
  (<.>) = (coerce :: WrapBinary PosFrac a) (<.>)
  zero = PosFrac zero
  one  = PosFrac one
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

instance (Eq a, Semiring a) => DetectableZero (PosFrac a) where
  isZero = (zero==)

instance (Ord a, Fractional a, Semiring a, HasPositiveInfinity a) =>
         StarSemiring (PosFrac a) where
    star (PosFrac n)
      | n < 1 = PosFrac (1 / (1 - n))
      | otherwise = PosFrac positiveInfinity

-- | Adds a star operation to integral types.
--
-- @('<+>')  = ('<+>')
--('<.>')  = ('<.>')
--'zero'   = 'zero'
--'one'    = 'one'
--'star' 0 = 1
--'star' _ = 'positiveInfinity'@
newtype PosInt a = PosInt
  { getPosInt :: a
  } deriving (Eq, Ord, Read, Show, Generic, Generic1, Num
             ,Enum, Typeable, Storable, Fractional, Real, RealFrac
             ,Functor, Foldable, Traversable)

instance (Bounded a, Semiring a) => Bounded (PosInt a) where
  minBound = PosInt zero
  maxBound = PosInt maxBound

instance Semiring a => Semiring (PosInt a) where
  (<+>) = (coerce :: WrapBinary PosInt a) (<+>)
  (<.>) = (coerce :: WrapBinary PosInt a) (<.>)
  zero = PosInt zero
  one  = PosInt one
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

instance (Eq a, Semiring a) => DetectableZero (PosInt a) where
  isZero = (zero==)

instance (Eq a, Semiring a, HasPositiveInfinity a) =>
         StarSemiring (PosInt a) where
    star (PosInt n) | n == zero = PosInt one
    star _          = PosInt positiveInfinity
