@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormThreshold("code-238", title: "title-588")
        let view = Consent.toConsentFormThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormThresholdViews([item, item]).count == 2)
    }
}
