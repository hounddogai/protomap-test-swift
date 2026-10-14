@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormCycle("code-867", name: "name-360")
        let view = Consent.toConsentFormCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormCycleViews([item, item]).count == 2)
    }
}
