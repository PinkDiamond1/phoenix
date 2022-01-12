package fr.acinq.phoenix.managers

import fr.acinq.bitcoin.ByteVector
import fr.acinq.bitcoin.ByteVector32
import fr.acinq.bitcoin.KeyPath
import fr.acinq.bitcoin.MnemonicCode
import fr.acinq.phoenix.data.Chain
import fr.acinq.phoenix.data.Wallet
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

@OptIn(ExperimentalCoroutinesApi::class)
class WalletManager(
    private val chain: Chain
) : CoroutineScope by MainScope() {

    private val _wallet = MutableStateFlow<Wallet?>(null)
    internal val wallet: StateFlow<Wallet?> = _wallet

    private val _hasWallet = MutableStateFlow<Boolean>(false)
    val hasWallet: StateFlow<Boolean> = _hasWallet

    init {
        launch {
            _wallet.collect {
                _hasWallet.value = it != null
            }
        }
    }

    // Converts a mnemonics list to a seed.
    // This is generally called with a mnemonics list that has been previously saved.
    fun mnemonicsToSeed(
        mnemonics: List<String>,
        wordList: List<String>,
        passphrase: String = ""
    ): ByteArray {
        MnemonicCode.validate(mnemonics = mnemonics, wordlist = wordList)
        return MnemonicCode.toSeed(mnemonics, passphrase)
    }

    fun loadWallet(seed: ByteArray): Pair<ByteVector32, String>? {
        if (_wallet.value != null) {
            return null
        }

        val newWallet = Wallet(seed, chain)
        _wallet.value = newWallet
        return newWallet.cloudKeyAndEncryptedNodeId()
    }

    fun getXpub(): Pair<String, KeyPath>? = _wallet.value?.xpub()
    fun getXprv(): Pair<String, KeyPath>? = _wallet.value?.xprv()
}
