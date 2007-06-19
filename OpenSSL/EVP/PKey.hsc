{- -*- haskell -*- -}
#include "HsOpenSSL.h"
module OpenSSL.EVP.PKey
    ( EvpPKey
    , EVP_PKEY

    , wrapPKey -- private
    , pkeySize -- private

      -- FIXME: newPKeyDSA, newPKeyDH and newPKeyECKey may be needed
#ifndef OPENSSL_NO_RSA
    , newPKeyRSA
#endif
    )
    where


import           Foreign
import           Foreign.C
import qualified GHC.ForeignPtr as GF
import           OpenSSL.RSA
import           OpenSSL.Utils


type EvpPKey  = ForeignPtr EVP_PKEY
data EVP_PKEY = EVP_PKEY


foreign import ccall unsafe "EVP_PKEY_new"
        _pkey_new :: IO (Ptr EVP_PKEY)

foreign import ccall unsafe "&EVP_PKEY_free"
        _pkey_free :: FunPtr (Ptr EVP_PKEY -> IO ())

foreign import ccall unsafe "EVP_PKEY_size"
        _pkey_size :: Ptr EVP_PKEY -> IO Int


wrapPKey :: Ptr EVP_PKEY -> IO (ForeignPtr EVP_PKEY)
wrapPKey = newForeignPtr _pkey_free


pkeySize :: EvpPKey -> IO Int
pkeySize pkey
    = withForeignPtr pkey $ \ pkeyPtr ->
      _pkey_size pkeyPtr


#ifndef OPENSSL_NO_RSA
foreign import ccall unsafe "EVP_PKEY_set1_RSA"
        _set1_RSA :: Ptr EVP_PKEY -> Ptr RSA_ -> IO Int

newPKeyRSA :: RSA -> IO EvpPKey
newPKeyRSA rsa
    = withForeignPtr rsa $ \ rsaPtr ->
      do pkeyPtr <- _pkey_new >>= failIfNull
         _set1_RSA pkeyPtr rsaPtr >>= failIf (/= 1)

         pkey <- wrapPKey pkeyPtr
         
         -- pkey refers to rsa
         GF.addForeignPtrConcFinalizer pkey $ touchForeignPtr rsa
         
         return pkey
#endif
