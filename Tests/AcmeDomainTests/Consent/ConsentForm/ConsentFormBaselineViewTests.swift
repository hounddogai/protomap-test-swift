@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormBaseline("code-608", name: "name-908")
        let view = Consent.toConsentFormBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormBaselineViews([item, item]).count == 2)
    }
}
