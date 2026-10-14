@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualGoalSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualGoalSummary("code-713", label: "label-565")
        let view = CareManagement.toManualGoalSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualGoalSummaryViews([item, item]).count == 2)
    }
}
