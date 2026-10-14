@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualDenialAgreement("code-198", name: "name-742")
        let view = RevenueCycle.toManualDenialAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualDenialAgreementViews([item, item]).count == 2)
    }
}
