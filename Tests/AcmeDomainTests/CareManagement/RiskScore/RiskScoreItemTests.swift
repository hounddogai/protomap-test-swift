@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreItemTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreItem("code-871", label: "label-454")
        #expect(item.status == CareManagement.RiskScoreItemStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newRiskScoreItem("code-871", label: "label-454")
        try item.moveTo(CareManagement.RiskScoreItemStatus.granted)
        #expect(item.status == CareManagement.RiskScoreItemStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreItem("code-871", label: "label-454")
        item.status = CareManagement.RiskScoreItemStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreItemStatus.requested) }
    }
}
