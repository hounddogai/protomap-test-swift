@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedTaskEntryTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCappedTaskEntry("code-755", name: "name-122")
        #expect(item.status == ClinicalOps.CappedTaskEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newCappedTaskEntry("code-755", name: "name-122")
        try item.moveTo(ClinicalOps.CappedTaskEntryStatus.rejected)
        #expect(item.status == ClinicalOps.CappedTaskEntryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCappedTaskEntry("code-755", name: "name-122")
        item.status = ClinicalOps.CappedTaskEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedTaskEntryStatus.proposed) }
    }
}
