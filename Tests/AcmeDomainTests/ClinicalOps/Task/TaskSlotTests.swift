@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSlotTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTaskSlot("code-24", name: "name-419")
        #expect(item.status == ClinicalOps.TaskSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newTaskSlot("code-24", name: "name-419")
        try item.moveTo(ClinicalOps.TaskSlotStatus.warming)
        #expect(item.status == ClinicalOps.TaskSlotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTaskSlot("code-24", name: "name-419")
        item.status = ClinicalOps.TaskSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskSlotStatus.idle) }
    }
}
