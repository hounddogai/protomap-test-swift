@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskEntryTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newStrictTaskEntry("code-252", label: "label-565")
        #expect(item.status == ClinicalOps.StrictTaskEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newStrictTaskEntry("code-252", label: "label-565")
        try item.moveTo(ClinicalOps.StrictTaskEntryStatus.resolved)
        #expect(item.status == ClinicalOps.StrictTaskEntryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newStrictTaskEntry("code-252", label: "label-565")
        item.status = ClinicalOps.StrictTaskEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictTaskEntryStatus.`open`) }
    }
}
