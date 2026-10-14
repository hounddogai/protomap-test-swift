@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDigestTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPrimaryOrderSetDigest("code-118", title: "title-984")
        #expect(item.status == ClinicalOps.PrimaryOrderSetDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newPrimaryOrderSetDigest("code-118", title: "title-984")
        try item.moveTo(ClinicalOps.PrimaryOrderSetDigestStatus.resolved)
        #expect(item.status == ClinicalOps.PrimaryOrderSetDigestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPrimaryOrderSetDigest("code-118", title: "title-984")
        item.status = ClinicalOps.PrimaryOrderSetDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryOrderSetDigestStatus.`open`) }
    }
}
