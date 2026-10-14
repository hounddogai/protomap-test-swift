@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalDenialMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalDenialMilestone("code-428", name: "name-717")
        let view = RevenueCycle.toGlobalDenialMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalDenialMilestoneViews([item, item]).count == 2)
    }
}
