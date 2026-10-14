@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalRemittanceAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        let view = RevenueCycle.toSeasonalRemittanceAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toSeasonalRemittanceAssignmentViews([item, item]).count == 2)
    }
}
