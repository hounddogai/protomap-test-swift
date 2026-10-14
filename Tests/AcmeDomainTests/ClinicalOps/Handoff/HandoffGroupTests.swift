@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffGroupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newHandoffGroup("code-719", title: "title-893")
        #expect(item.status == ClinicalOps.HandoffGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newHandoffGroup("code-719", title: "title-893")
        try item.moveTo(ClinicalOps.HandoffGroupStatus.done)
        #expect(item.status == ClinicalOps.HandoffGroupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newHandoffGroup("code-719", title: "title-893")
        item.status = ClinicalOps.HandoffGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffGroupStatus.new) }
    }
}
