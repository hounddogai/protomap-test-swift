@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalClaimAgreement("code-990", name: "name-102")
        let view = RevenueCycle.toGlobalClaimAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalClaimAgreementViews([item, item]).count == 2)
    }
}
