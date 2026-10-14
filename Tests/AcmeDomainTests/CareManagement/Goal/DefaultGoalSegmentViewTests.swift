@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultGoalSegment("code-989", title: "title-699")
        let view = CareManagement.toDefaultGoalSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultGoalSegmentViews([item, item]).count == 2)
    }
}
