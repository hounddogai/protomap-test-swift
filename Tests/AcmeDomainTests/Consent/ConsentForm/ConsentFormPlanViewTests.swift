@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormPlan("code-215", name: "name-45")
        let view = Consent.toConsentFormPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormPlanViews([item, item]).count == 2)
    }
}
