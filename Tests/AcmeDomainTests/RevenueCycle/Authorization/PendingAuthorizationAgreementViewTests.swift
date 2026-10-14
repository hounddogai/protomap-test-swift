@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingAuthorizationAgreement("code-148", title: "title-454")
        let view = RevenueCycle.toPendingAuthorizationAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingAuthorizationAgreementViews([item, item]).count == 2)
    }
}
