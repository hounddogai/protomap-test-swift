@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingRiskScoreCheckpoint("code-746", label: "label-376")
        let view = CareManagement.toPendingRiskScoreCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingRiskScoreCheckpointViews([item, item]).count == 2)
    }
}
