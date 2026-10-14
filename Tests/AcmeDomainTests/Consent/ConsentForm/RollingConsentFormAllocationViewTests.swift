@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        let view = Consent.toRollingConsentFormAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingConsentFormAllocationViews([item, item]).count == 2)
    }
}
