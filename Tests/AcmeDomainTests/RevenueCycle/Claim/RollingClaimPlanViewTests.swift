@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingClaimPlan("code-889", title: "title-162")
        let view = RevenueCycle.toRollingClaimPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingClaimPlanViews([item, item]).count == 2)
    }
}
