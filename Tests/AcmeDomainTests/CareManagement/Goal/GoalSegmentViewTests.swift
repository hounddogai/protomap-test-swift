@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalSegment("code-4", title: "title-208")
        let view = CareManagement.toGoalSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalSegmentViews([item, item]).count == 2)
    }
}
