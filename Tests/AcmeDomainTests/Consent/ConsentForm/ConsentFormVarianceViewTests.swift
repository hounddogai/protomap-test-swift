@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        let view = Consent.toConsentFormVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormVarianceViews([item, item]).count == 2)
    }
}
