@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualChargeAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualChargeAssignment("code-632", name: "name-309")
        let view = RevenueCycle.toManualChargeAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualChargeAssignmentViews([item, item]).count == 2)
    }
}
