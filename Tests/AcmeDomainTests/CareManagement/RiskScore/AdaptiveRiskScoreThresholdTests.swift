@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreThresholdTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        #expect(item.status == CareManagement.AdaptiveRiskScoreThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        try item.moveTo(CareManagement.AdaptiveRiskScoreThresholdStatus.granted)
        #expect(item.status == CareManagement.AdaptiveRiskScoreThresholdStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        item.status = CareManagement.AdaptiveRiskScoreThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveRiskScoreThresholdStatus.requested) }
    }
}
