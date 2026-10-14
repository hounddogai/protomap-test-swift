@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalSummary("code-648", title: "title-699")
        let view = CareManagement.toGoalSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalSummaryViews([item, item]).count == 2)
    }
}
