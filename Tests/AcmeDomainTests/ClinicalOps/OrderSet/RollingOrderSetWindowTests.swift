@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingOrderSetWindowTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        #expect(item.status == ClinicalOps.RollingOrderSetWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        try item.moveTo(ClinicalOps.RollingOrderSetWindowStatus.queued)
        #expect(item.status == ClinicalOps.RollingOrderSetWindowStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        item.status = ClinicalOps.RollingOrderSetWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingOrderSetWindowStatus.new) }
    }
}
