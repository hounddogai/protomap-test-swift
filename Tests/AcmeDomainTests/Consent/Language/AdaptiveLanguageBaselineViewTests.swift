@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveLanguageBaseline("code-846", name: "name-675")
        let view = Consent.toAdaptiveLanguageBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveLanguageBaselineViews([item, item]).count == 2)
    }
}
