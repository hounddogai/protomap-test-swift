@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedLanguageTarget("code-639", label: "label-963")
        let view = Consent.toBatchedLanguageTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedLanguageTargetViews([item, item]).count == 2)
    }
}
