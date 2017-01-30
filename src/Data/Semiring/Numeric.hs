{-# LANGUAGE DeriveFoldable             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DeriveTraversable          #-}
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
  , Log(..)
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
             ,Functor, Foldable, Traversable)

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
             ,Functor, Foldable, Traversable)

instance (Ord a, Semiring a) => Semiring (Viterbi a) where
  (<+>) = (coerce :: WrapBinary Viterbi a) max
  (<.>) = (coerce :: WrapBinary Viterbi a) (<.>)
  zero = Viterbi zero
  one  = Viterbi one
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}

-- | Useful for optimizing multiplication, or working with large numbers.
--
-- @('<.>')   = ('+')
--x '<+>' y = -('log' ('exp' (-x) + 'exp' (-y)))
--'zero'    = ∞
--'one'     = 0@
newtype Log a = Log
  { getLog :: a
  } deriving (Eq, Ord, Read, Show, Generic, Generic1, Typeable, Functor
             ,Foldable)

instance (Floating a, HasPositiveInfinity a) => Semiring (Log a) where
  zero = Log positiveInfinity
  one = Log 0
  (<.>) = (coerce :: WrapBinary Log a) (+)
  Log x <+> Log y
    = Log (-(log (exp (-x) + exp (-y))))
  {-# INLINE (<+>) #-}
  {-# INLINE (<.>) #-}
  {-# INLINE zero #-}
  {-# INLINE one #-}
