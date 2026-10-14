@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        let view = Consent.toPendingConsentFormAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingConsentFormAllocationViews([item, item]).count == 2)
    }
}
