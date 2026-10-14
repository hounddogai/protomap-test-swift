@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeAuditTests {
    @Test func startsInOpen() throws {
        let item = Labs.newRegionalReferenceRangeAudit("code-369", label: "label-748")
        #expect(item.status == Labs.RegionalReferenceRangeAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newRegionalReferenceRangeAudit("code-369", label: "label-748")
        try item.moveTo(Labs.RegionalReferenceRangeAuditStatus.inReview)
        #expect(item.status == Labs.RegionalReferenceRangeAuditStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newRegionalReferenceRangeAudit("code-369", label: "label-748")
        item.status = Labs.RegionalReferenceRangeAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalReferenceRangeAuditStatus.`open`) }
    }
}
