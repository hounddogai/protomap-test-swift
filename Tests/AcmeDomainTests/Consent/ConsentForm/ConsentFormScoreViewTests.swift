@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormScore("code-867", name: "name-734")
        let view = Consent.toConsentFormScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormScoreViews([item, item]).count == 2)
    }
}
