@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskEntryTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newTaskEntry("code-189", title: "title-125")
        #expect(item.status == ClinicalOps.TaskEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newTaskEntry("code-189", title: "title-125")
        try item.moveTo(ClinicalOps.TaskEntryStatus.revoked)
        #expect(item.status == ClinicalOps.TaskEntryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newTaskEntry("code-189", title: "title-125")
        item.status = ClinicalOps.TaskEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskEntryStatus.requested) }
    }
}
