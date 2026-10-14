@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffSlotTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newPrimaryHandoffSlot("code-965", name: "name-713")
        #expect(item.status == ClinicalOps.PrimaryHandoffSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newPrimaryHandoffSlot("code-965", name: "name-713")
        try item.moveTo(ClinicalOps.PrimaryHandoffSlotStatus.queued)
        #expect(item.status == ClinicalOps.PrimaryHandoffSlotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newPrimaryHandoffSlot("code-965", name: "name-713")
        item.status = ClinicalOps.PrimaryHandoffSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryHandoffSlotStatus.new) }
    }
}
