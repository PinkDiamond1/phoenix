import SwiftUI
import PhoenixShared
import os.log

#if DEBUG && true
fileprivate var log = Logger(
	subsystem: Bundle.main.bundleIdentifier!,
	category: "InitializationView"
)
#else
fileprivate var log = Logger(OSLog.disabled)
#endif


struct InitializationView: MVIView {
	
	@StateObject var mvi = MVIState({ $0.initialization() })
	
	@Environment(\.controllerFactory) var factoryEnv
	var factory: ControllerFactory { return factoryEnv }
	
	enum ButtonWidth: Preference {}
	let buttonWidthReader = GeometryPreferenceReader(
		key: AppendValue<ButtonWidth>.self,
		value: { [$0.size.width] }
	)
	@State var buttonWidth: CGFloat? = nil
	
	@State var mnemonicLanguage = MnemonicLanguage.english
	
	@ViewBuilder
	var view: some View {
		
		ZStack {
			
			Color.primaryBackground
				.edgesIgnoringSafeArea(.all)
			
			if AppDelegate.showTestnetBackground {
				Image("testnet_bg")
					.resizable(resizingMode: .tile)
					.edgesIgnoringSafeArea([.horizontal, .bottom]) // not underneath status bar
			}
			
			// Position the settings icon in top-right corner.
			HStack{
				Spacer()
				VStack {
					NavigationLink(destination: ConfigurationView()) {
						Image(systemName: "gearshape")
							.renderingMode(.template)
							.imageScale(.large)
					}
					Spacer()
				}
				.padding(.all, 20)
			}
			
			// Primary content
			VStack(alignment: HorizontalAlignment.center, spacing: 0) {
			
				Spacer()
				
				Image(logoImageName)
					.resizable()
					.frame(width: 96, height: 96)

				Text("Phoenix")
					.font(Font.title2)
					.padding(.top, -10)
					.padding(.bottom, 80)
				
				Button {
					createMnemonics()
				} label: {
					HStack(alignment: VerticalAlignment.firstTextBaseline) {
						Image(systemName: "flame")
							.imageScale(.small)
						Text("Create new wallet")
					}
					.read(buttonWidthReader)
					.frame(width: buttonWidth)
					.font(.title3)
					.padding([.top, .bottom], 8)
					.padding([.leading, .trailing], 16)
				}
				.buttonStyle(
					ScaleButtonStyle(
						backgroundFill: Color.primaryBackground,
						borderStroke: Color.appAccent,
						disabledBorderStroke: Color(UIColor.separator)
					)
				)
				.padding(.bottom, 8)
				
				NavigationLink(destination: InitializationOptionsView(mnemonicLanguage: $mnemonicLanguage)) {
					Text("advanced options")
						.font(.subheadline)
				}
				.padding(.bottom, 40)

				NavigationLink(destination: RestoreView()) {
					HStack(alignment: VerticalAlignment.firstTextBaseline) {
						Image(systemName: "arrow.down.circle")
							.imageScale(.small)
						Text("Restore my wallet")
					}
					.read(buttonWidthReader)
					.frame(width: buttonWidth)
					.font(.title3)
					.padding([.top, .bottom], 8)
					.padding([.leading, .trailing], 16)
				}
				.buttonStyle(
					ScaleButtonStyle(
						backgroundFill: Color.primaryBackground,
						borderStroke: Color.appAccent,
						disabledBorderStroke: Color(UIColor.separator)
					)
				)
				.padding([.top, .bottom], 0)
				
				Spacer() // 2 spacers at bottom
				Spacer() // move center upwards; focus is buttons, not logo

			} // </VStack>
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			
		} // </ZStack>
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.assignMaxPreference(for: buttonWidthReader.key, to: $buttonWidth)
		.navigationBarTitle("", displayMode: .inline)
		.navigationBarHidden(true)
		.onChange(of: mvi.model, perform: { model in
			onModelChange(model: model)
		})
	}
	
	var logoImageName: String {
		if AppDelegate.isTestnet {
			return "logo_blue"
		} else {
			return "logo_green"
		}
	}
	
	func createMnemonics() -> Void {
		log.trace("createMnemonics()")
		
		let swiftEntropy = AppSecurity.shared.generateEntropy()
		let kotlinEntropy = swiftEntropy.toKotlinByteArray()
		
		mvi.intent(Initialization.IntentGenerateWallet(
			entropy: kotlinEntropy,
			language: mnemonicLanguage
		))
	}
	
	func onModelChange(model: Initialization.Model) -> Void {
		log.trace("onModelChange()")
	
		if let model = model as? Initialization.ModelGeneratedWallet {
			createWallet(model: model)
		}
	}
	
	func createWallet(model: Initialization.ModelGeneratedWallet) -> Void {
		log.trace("createWallet()")
		
		let recoveryPhrase = RecoveryPhrase(
			mnemonics: model.mnemonics,
			languageCode: model.language.code
		)
		
		AppSecurity.shared.addKeychainEntry(recoveryPhrase: recoveryPhrase) { (error: Error?) in
			if error == nil {
				AppDelegate.get().loadWallet(recoveryPhrase: recoveryPhrase, seed: model.seed)
			}
		}
	}
}

struct InitializationOptionsView: View {
	
	@Binding var mnemonicLanguage: MnemonicLanguage
	
	@ViewBuilder
	var body: some View {
		
		ZStack {
			Color.primaryBackground
				.edgesIgnoringSafeArea(.all)
			
			if AppDelegate.showTestnetBackground {
				Image("testnet_bg")
					.resizable(resizingMode: .tile)
					.edgesIgnoringSafeArea([.horizontal, .bottom]) // not underneath status bar
			}
			
			content
		}
		.navigationBarTitle(
			NSLocalizedString("Advanced Options", comment: "Navigation bar title"),
			displayMode: .inline
		)
	}
	
	@ViewBuilder
	var content: some View {
		
		List {
			Section(header: Text("BIP39 Mnemonic")) {
				ForEach(MnemonicLanguage.allCases, id: \.code) { lang in
					Toggle(isOn: Binding(
						get: { mnemonicLanguage == lang },
						set: { if $0 { mnemonicLanguage = lang }}
					)) {
						Text(verbatim: "\(lang.flag) \(lang.displayName)")
					}
					.toggleStyle(CheckboxToggleStyle(
						onImage: onImage(),
						offImage: offImage()
					))
					.padding(.vertical, 5)
					
				} // </ForEach>
			} // </Section>
			
			Section(header: Text("Notes")) {
				Text(styled: NSLocalizedString(
					"""
					Your recovery phrase is 12 words, generated using the BIP39 standard.
					
					In extreme circumstances (for example, if Phoenix is removed from the App Store) \
					you may need to recover your funds using a different wallet. In this case, English \
					offers the highest compatibility with other wallets.
					
					Unfortunately, many other wallets neglect non-English speaking users. 🥺
					
					However, if you prefer another language, we provide detailed recovery instructions \
					for non-English mnemonics on our website.
					
					Your selection here does **not** affect your ability to send or receive bitcoin \
					within Phoenix.
					""",
					comment: "Intialization: Advanced options"
				))
				.font(.callout)
				.padding(.vertical, 5)
			} // </Section>
		} // </List>
	}
	
	@ViewBuilder
	func onImage() -> some View {
		Image(systemName: "checkmark.square.fill")
			.imageScale(.large)
	}
	
	@ViewBuilder
	func offImage() -> some View {
		Image(systemName: "square")
			.imageScale(.large)
	}
}

// MARK: -

class InitView_Previews : PreviewProvider {

	static var previews: some View {
		InitializationView()
			.preferredColorScheme(.light)
			.previewDevice("iPhone 8")
			
		InitializationView()
			.preferredColorScheme(.dark)
			.previewDevice("iPhone 8")
			
		InitializationView()
			.preferredColorScheme(.light)
			.previewDevice("iPhone 11")
    }
}
