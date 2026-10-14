@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("code-665", name: "name-891")
        let view = CareManagement.toAdaptiveRiskScoreCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveRiskScoreCheckpointViews([item, item]).count == 2)
    }
}
