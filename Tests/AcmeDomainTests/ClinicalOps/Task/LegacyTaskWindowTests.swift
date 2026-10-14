@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskWindowTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newLegacyTaskWindow("code-190", title: "title-657")
        #expect(item.status == ClinicalOps.LegacyTaskWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newLegacyTaskWindow("code-190", title: "title-657")
        try item.moveTo(ClinicalOps.LegacyTaskWindowStatus.reopened)
        #expect(item.status == ClinicalOps.LegacyTaskWindowStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newLegacyTaskWindow("code-190", title: "title-657")
        item.status = ClinicalOps.LegacyTaskWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyTaskWindowStatus.`open`) }
    }
}
