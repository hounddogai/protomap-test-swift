@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveConsentFormAllocation("code-854", name: "name-487")
        let view = Consent.toAdaptiveConsentFormAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveConsentFormAllocationViews([item, item]).count == 2)
    }
}
