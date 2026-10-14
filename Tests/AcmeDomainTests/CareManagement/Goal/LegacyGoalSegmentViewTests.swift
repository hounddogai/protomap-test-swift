@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyGoalSegment("code-389", label: "label-715")
        let view = CareManagement.toLegacyGoalSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyGoalSegmentViews([item, item]).count == 2)
    }
}
