@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormEstimate("code-463", title: "title-797")
        let view = Consent.toConsentFormEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormEstimateViews([item, item]).count == 2)
    }
}
