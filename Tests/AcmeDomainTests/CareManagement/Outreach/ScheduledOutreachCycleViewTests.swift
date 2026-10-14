@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledOutreachCycle("code-164", label: "label-379")
        let view = CareManagement.toScheduledOutreachCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledOutreachCycleViews([item, item]).count == 2)
    }
}
