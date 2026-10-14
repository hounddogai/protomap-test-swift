@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedClaimAssignment("code-152", title: "title-119")
        let view = RevenueCycle.toWeightedClaimAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedClaimAssignmentViews([item, item]).count == 2)
    }
}
