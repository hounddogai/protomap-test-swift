@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBundleTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newHandoffBundle("code-341", title: "title-505")
        #expect(item.status == ClinicalOps.HandoffBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newHandoffBundle("code-341", title: "title-505")
        try item.moveTo(ClinicalOps.HandoffBundleStatus.inReview)
        #expect(item.status == ClinicalOps.HandoffBundleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newHandoffBundle("code-341", title: "title-505")
        item.status = ClinicalOps.HandoffBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffBundleStatus.`open`) }
    }
}
