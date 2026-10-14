@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalAssessmentCheckpoint("code-188", name: "name-577")
        let view = CareManagement.toGlobalAssessmentCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalAssessmentCheckpointViews([item, item]).count == 2)
    }
}
