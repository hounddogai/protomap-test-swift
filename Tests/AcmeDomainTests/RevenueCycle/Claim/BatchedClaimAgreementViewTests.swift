@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedClaimAgreement("code-919", label: "label-994")
        let view = RevenueCycle.toBatchedClaimAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedClaimAgreementViews([item, item]).count == 2)
    }
}
