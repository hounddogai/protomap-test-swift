@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachScoreTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newTieredOutreachScore("code-443", name: "name-394")
        #expect(item.status == CareManagement.TieredOutreachScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newTieredOutreachScore("code-443", name: "name-394")
        try item.moveTo(CareManagement.TieredOutreachScoreStatus.queued)
        #expect(item.status == CareManagement.TieredOutreachScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newTieredOutreachScore("code-443", name: "name-394")
        item.status = CareManagement.TieredOutreachScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredOutreachScoreStatus.new) }
    }
}
