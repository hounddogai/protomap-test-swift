@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskWindowTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newGlobalTaskWindow("code-68", name: "name-681")
        #expect(item.status == ClinicalOps.GlobalTaskWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newGlobalTaskWindow("code-68", name: "name-681")
        try item.moveTo(ClinicalOps.GlobalTaskWindowStatus.pending)
        #expect(item.status == ClinicalOps.GlobalTaskWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newGlobalTaskWindow("code-68", name: "name-681")
        item.status = ClinicalOps.GlobalTaskWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalTaskWindowStatus.draft) }
    }
}
