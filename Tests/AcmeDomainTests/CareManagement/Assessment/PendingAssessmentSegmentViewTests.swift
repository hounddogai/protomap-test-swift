@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        let view = CareManagement.toPendingAssessmentSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingAssessmentSegmentViews([item, item]).count == 2)
    }
}
