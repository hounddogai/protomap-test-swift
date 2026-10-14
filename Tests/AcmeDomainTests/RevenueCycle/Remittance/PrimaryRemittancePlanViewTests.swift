@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittancePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPrimaryRemittancePlan("code-832", name: "name-978")
        let view = RevenueCycle.toPrimaryRemittancePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPrimaryRemittancePlanViews([item, item]).count == 2)
    }
}
