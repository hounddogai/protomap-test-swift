@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffRecordTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newHandoffRecord("code-23", title: "title-384")
        #expect(item.status == ClinicalOps.HandoffRecordStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newHandoffRecord("code-23", title: "title-384")
        try item.moveTo(ClinicalOps.HandoffRecordStatus.published)
        #expect(item.status == ClinicalOps.HandoffRecordStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newHandoffRecord("code-23", title: "title-384")
        item.status = ClinicalOps.HandoffRecordStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffRecordStatus.created) }
    }
}
