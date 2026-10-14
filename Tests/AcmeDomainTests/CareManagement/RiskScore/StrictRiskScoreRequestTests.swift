@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreRequestTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newStrictRiskScoreRequest("code-195", name: "name-209")
        #expect(item.status == CareManagement.StrictRiskScoreRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newStrictRiskScoreRequest("code-195", name: "name-209")
        try item.moveTo(CareManagement.StrictRiskScoreRequestStatus.running)
        #expect(item.status == CareManagement.StrictRiskScoreRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newStrictRiskScoreRequest("code-195", name: "name-209")
        item.status = CareManagement.StrictRiskScoreRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictRiskScoreRequestStatus.new) }
    }
}
