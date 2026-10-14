@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackRiskScoreCheckpoint("code-911", title: "title-523")
        let view = CareManagement.toFallbackRiskScoreCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackRiskScoreCheckpointViews([item, item]).count == 2)
    }
}
