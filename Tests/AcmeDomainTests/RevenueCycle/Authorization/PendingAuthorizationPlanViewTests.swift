@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingAuthorizationPlan("code-845", name: "name-83")
        let view = RevenueCycle.toPendingAuthorizationPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingAuthorizationPlanViews([item, item]).count == 2)
    }
}
