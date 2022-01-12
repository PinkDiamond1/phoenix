import SwiftUI
import PhoenixShared
import os.log

#if DEBUG && true
fileprivate var log = Logger(
	subsystem: Bundle.main.bundleIdentifier!,
	category: "ManualBackupView"
)
#else
fileprivate var log = Logger(OSLog.disabled)
#endif

struct ManualBackupView : View {
	
	@Binding var manualBackup_taskDone: Bool
	
	@State var isDecrypting = false
	@State var revealSeed = false
	@State var recoveryPhrase: RecoveryPhrase? = nil
	
	let encryptedNodeId: String
	@State var legal_taskDone: Bool
	@State var legal_lossRisk: Bool
	
	@State var animatingLegalToggleColor = false
	
	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	
	var canSave: Bool {
		if manualBackup_taskDone {
			// Currently enabled.
			// Saving to disable: user only needs to disable the taskDone toggle
			return !legal_taskDone
		} else {
			// Currently disabled.
			// To enable, user must enable both toggles
			return legal_taskDone && legal_lossRisk
		}
	}
	
	init(manualBackup_taskDone: Binding<Bool>) {
		self._manualBackup_taskDone = manualBackup_taskDone
		
		let encryptedNodeId = AppDelegate.get().encryptedNodeId!
		self.encryptedNodeId = encryptedNodeId
		
		self._legal_taskDone = State<Bool>(initialValue: manualBackup_taskDone.wrappedValue)
		self._legal_lossRisk = State<Bool>(initialValue: manualBackup_taskDone.wrappedValue)
	}
	
	var body: some View {
		
		List {
			section_info()
			section_button()
			section_legal()
		}
		.sheet(isPresented: $revealSeed) {
			
			if let recoveryPhrase = recoveryPhrase {
				RecoverySeedReveal(
					isShowing: $revealSeed,
					recoveryPhrase: recoveryPhrase
				)
			} else {
				EmptyView()
			}
		}
		.navigationBarTitle(
			NSLocalizedString("Manual Backup", comment: "Navigation bar title"),
			displayMode: .inline
		)
		.navigationBarBackButtonHidden(true)
		.navigationBarItems(leading: backButton())
		.onAppear {
			onAppear()
		}
	}
	
	@ViewBuilder
	func backButton() -> some View {
		
		Button {
			didTapBackButton()
		} label: {
			HStack(alignment: VerticalAlignment.center, spacing: 0) {
				Image(systemName: "chevron.left")
					 .font(.title2)
				if canSave {
					Text("Save")
				} else {
					Text("Cancel")
				}
			}
		}
	}
	
	@ViewBuilder
	func section_info() -> some View {
		
		Section {
			
			VStack(alignment: .leading, spacing: 35) {
				Text(
					"""
					The recovery phrase (sometimes called a seed), is a list of 12 words. \
					It allows you to recover full access to your funds if needed.
					"""
				)
				
				Text(
					"Only you alone possess this seed. Keep it private."
				)
				.fontWeight(.bold)
				
				Text(styled: NSLocalizedString(
					"""
					**Do not share this seed with anyone.** \
					Beware of phishing. The developers of Phoenix will never ask for your seed.
					""",
					comment: "ManualBackupView"
				))
				
				Text(styled: NSLocalizedString(
					"""
					**Do not lose this seed.** \
					Save it somewhere safe (not on this phone). \
					If you lose your seed and your phone, you've lost your funds.
					""",
					comment: "ManualBackupView"
				))
					
			} // </VStack>
			.padding(.vertical, 15)
			
		} // </Section>
	}
	
	@ViewBuilder
	func section_button() -> some View {
		
		Section {
			
			VStack(alignment: HorizontalAlignment.center, spacing: 0) {
				
				Button {
					decrypt()
				} label: {
					HStack {
						Image(systemName: "key")
							.imageScale(.medium)
						Text("Display seed")
							.font(.headline)
					}
				}
				.disabled(isDecrypting)
				.padding(.vertical, 5)
				
				let enabledSecurity = AppSecurity.shared.enabledSecurity.value
				if enabledSecurity != .none {
					Text("(requires authentication)")
						.font(.footnote)
						.foregroundColor(.secondary)
						.padding(.top, 5)
						.padding(.bottom, 10)
				}
			} // </VStack>
			.frame(maxWidth: .infinity)
			
		} // </Section>
	}
	
	@ViewBuilder
	func section_legal() -> some View {
		
		Section {
			
			Toggle(isOn: $legal_taskDone) {
				Text(
					"""
					I have saved my recovery phrase somewhere safe.
					"""
				)
				.lineLimit(nil)
				.alignmentGuide(VerticalAlignment.center) { d in
					d[VerticalAlignment.firstTextBaseline]
				}
			}
			.toggleStyle(CheckboxToggleStyle(
				onImage: onImage(),
				offImage: offImage()
			))
			.padding(.vertical, 5)
			
			Toggle(isOn: $legal_lossRisk) {
				Text(
					"""
					I understand that if I lose my phone & my recovery phrase, \
					then I will lose the funds in my wallet.
					"""
				)
				.lineLimit(nil)
				.alignmentGuide(VerticalAlignment.center) { d in
					d[VerticalAlignment.firstTextBaseline]
				}
			}
			.toggleStyle(CheckboxToggleStyle(
				onImage: onImage(),
				offImage: offImage()
			))
			.padding(.vertical, 5)
			
		} header: {
			Text("Legal")
			
		} // </Section>
	}
	
	@ViewBuilder
	func onImage() -> some View {
		Image(systemName: "checkmark.square.fill")
			.imageScale(.large)
	}
	
	@ViewBuilder
	func offImage() -> some View {
		Image(systemName: "square")
			.renderingMode(.template)
			.imageScale(.large)
			.foregroundColor(animatingLegalToggleColor ? Color.red : Color.primary)
	}
	
	func onAppear(){
		log.trace("onAppear()")
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: true)) {
				animatingLegalToggleColor = true
			}
		}
	}
	
	func decrypt() {
		log.trace("decrypt()")
		
		isDecrypting = true
		
		let Succeed = {(result: RecoveryPhrase) in
			recoveryPhrase = result
			revealSeed = true
			isDecrypting = false
		}
		
		let Fail = {
			isDecrypting = false
		}
		
		let enabledSecurity = AppSecurity.shared.enabledSecurity.value
		if enabledSecurity == .none {
			AppSecurity.shared.tryUnlockWithKeychain { (recoveryPhrase, _, _) in
				
				if let recoveryPhrase = recoveryPhrase {
					Succeed(recoveryPhrase)
				} else {
					Fail()
				}
			}
		} else {
			let prompt = NSLocalizedString("Unlock your seed.", comment: "Biometrics prompt")
			
			AppSecurity.shared.tryUnlockWithBiometrics(prompt: prompt) { result in
				if case .success(let recoveryPhrase) = result {
					Succeed(recoveryPhrase)
				} else {
					Fail()
				}
			}
		}
	}
	
	func didTapBackButton() {
		log.trace("didTapBackButton()")
		
		if canSave {
			let taskDone = legal_taskDone && legal_lossRisk
			
			manualBackup_taskDone = taskDone
			Prefs.shared.manualBackup_setTaskDone(taskDone, encryptedNodeId: encryptedNodeId)
		}
		presentationMode.wrappedValue.dismiss()
	}

}

struct RecoverySeedReveal: View, ViewName {
	
	@Binding var isShowing: Bool
	let recoveryPhrase: RecoveryPhrase
	let language: MnemonicLanguage
	
	@State var showCopyOptions = false
	
	@StateObject var toast = Toast()
	@Environment(\.colorScheme) var colorScheme: ColorScheme
	
	init(isShowing: Binding<Bool>, recoveryPhrase: RecoveryPhrase) {
		self._isShowing = isShowing
		self.recoveryPhrase = recoveryPhrase
		self.language = recoveryPhrase.language ?? MnemonicLanguage.english
	}
	
	func mnemonic(_ idx: Int) -> String {
		let mnemonics = recoveryPhrase.mnemonicsArray
		return (mnemonics.count > idx) ? mnemonics[idx] : " "
	}
	
	@ViewBuilder
	var body: some View {
		
		ZStack {
			
			// close button
			// (required for landscape mode, where swipe to dismiss isn't possible)
			VStack {
				HStack(alignment: VerticalAlignment.center, spacing: 0) {
					Text(verbatim: "\(language.flag) \(language.displayName)")
						.font(.callout)
						.foregroundColor(.secondary)
					Spacer()
					Button {
						close()
					} label: {
						Image("ic_cross")
							.resizable()
							.frame(width: 30, height: 30)
					}
				}
				Spacer()
			}
			.padding()
			
			main
			toast.view()
		}
	}
	
	@ViewBuilder
	var main: some View {
		
		VStack {
			
			Spacer()
			
			Text("KEEP THIS SEED SAFE.")
				.font(.title2)
				.multilineTextAlignment(.center)
				.padding(.bottom, 2)
			Text("DO NOT SHARE.")
				.multilineTextAlignment(.center)
				.font(.title2)
			
			Spacer()
			
			HStack {
				Spacer()
				
				VStack {
					ForEach(0..<6, id: \.self) { idx in
						Text(verbatim: "#\(idx + 1) ")
							.font(.headline)
							.foregroundColor(.secondary)
							.padding(.bottom, 2)
					}
				}
				.padding(.trailing, 2)
				
				VStack(alignment: .leading) {
					ForEach(0..<6, id: \.self) { idx in
						Text(mnemonic(idx))
							.font(.headline)
							.padding(.bottom, 2)
					}
				}
				.padding(.trailing, 4) // boost spacing a wee bit
				
				Spacer()
				
				VStack {
					ForEach(6..<12, id: \.self) { idx in
						Text(verbatim: "#\(idx + 1) ")
							.font(.headline)
							.foregroundColor(.secondary)
							.padding(.bottom, 2)
					}
				}
				.padding(.trailing, 2)
				
				VStack(alignment: .leading) {
					ForEach(6..<12, id: \.self) { idx in
						Text(mnemonic(idx))
							.font(.headline)
							.padding(.bottom, 2)
					}
				}
				
				Spacer()
			}
			.padding(.top, 20)
			.padding(.bottom, 10)
			
			Spacer()
			Spacer()
			
			copyButton
				.padding(.bottom, 6)
			Text("BIP39 seed with standard BIP84 derivation path")
				.font(.footnote)
				.foregroundColor(.secondary)
			
		}
		.padding(.top, 20)
		.padding([.leading, .trailing], 30)
		.padding(.bottom, 20)
	}
	
	@ViewBuilder
	var copyButton: some View {
		
		let xprv = AppDelegate.isTestnet ? "vprv" : "zprv"
		let xpub = AppDelegate.isTestnet ? "vpub" : "zpub"
  		
		HStack(alignment: VerticalAlignment.center, spacing: 0) {
			Spacer()
			if #available(iOS 15.0, *) {
				
				Button {
					showCopyOptions = true
				} label: {
					Text("Copy…").font(.title3)
				}
				.confirmationDialog("What would you like to copy?",
					isPresented: $showCopyOptions,
					titleVisibility: .automatic
				) {
					// Note: confirmationDialog strips all formatting from Text items.
					// So we don't get to play with fonts or colors here.
					Button("Recovery phrase (12 words)") {
						copyRecoveryPhrase()
					}
					Button("Account extended private key (\(xprv))") {
						copyExtPrivKey()
					}
					Button("Account extended public key (\(xpub))") {
						copyExtPubKey()
					}
				}
				
			} else /* iOS 14 */ {
				
				Button {
					showCopyOptions = true
				} label: {
					Text("Copy…").font(.title3)
				}
				.actionSheet(isPresented: $showCopyOptions) {
					ActionSheet(
						title: Text("What would you like to copy?"),
						buttons: [
							.default(Text("Recovery phrase (12 words)")) {
								copyRecoveryPhrase()
							},
							.default(Text("Account extended private key (\(xprv))")) {
								copyExtPrivKey()
							},
							.default(Text("Account extended public key (\(xpub))")) {
								copyExtPubKey()
							},
						]
					)
				}
				
			}
			Spacer()
		}
	}
	
	func copyRecoveryPhrase() {
		log.trace("[\(viewName)] copyRecoveryPhrase()")
		
		copy(recoveryPhrase.mnemonics)
	}
	
	func copyExtPrivKey() {
		log.trace("[\(viewName)] copyExtPrivKey()")
		
		let business = AppDelegate.get().business
		if let xprv = business.walletManager.getXprv()?.first {
			copy(xprv as String)
		}
	}
	
	func copyExtPubKey() {
		log.trace("[\(viewName)] copyExtPubKey()")
		
		let business = AppDelegate.get().business
		if let xpub = business.walletManager.getXpub()?.first {
			copy(xpub as String)
		}
	}
	
	private func copy(_ string: String) {
		log.trace("[\(viewName)] copy()")
		
		UIPasteboard.general.string = string
		AppDelegate.get().clearPasteboardOnReturnToApp = true
		toast.pop(
			Text("Pasteboard will be cleared when you return to Phoenix.")
				.multilineTextAlignment(.center)
				.anyView,
			colorScheme: colorScheme.opposite,
			duration: 4.0 // seconds
		)
	}
	
	func close() {
		log.trace("[\(viewName)] close()")
		isShowing = false
	}
}

class RecoverySeedView_Previews: PreviewProvider {
	
	@State static var manualBackup_taskDone: Bool = true
	@State static var revealSeed: Bool = true
	
	static let recoveryPhrase = RecoveryPhrase(
		mnemonics: "witch collapse practice feed shame open despair creek road again ice least",
		language: MnemonicLanguage.english
	)
	
	static var previews: some View {
		
		ManualBackupView(manualBackup_taskDone: $manualBackup_taskDone)
			.preferredColorScheme(.light)
			.previewDevice("iPhone 8")
		
		ManualBackupView(manualBackup_taskDone: $manualBackup_taskDone)
			.preferredColorScheme(.dark)
			.previewDevice("iPhone 8")
		
		RecoverySeedReveal(isShowing: $revealSeed, recoveryPhrase: recoveryPhrase)
			.preferredColorScheme(.light)
			.previewDevice("iPhone 8")
		
		RecoverySeedReveal(isShowing: $revealSeed, recoveryPhrase: recoveryPhrase)
			.preferredColorScheme(.dark)
			.previewDevice("iPhone 8")
	}
}
