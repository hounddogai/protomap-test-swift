@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertNoticeTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAlertNotice("code-143", name: "name-204")
        #expect(item.status == ClinicalOps.AlertNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newAlertNotice("code-143", name: "name-204")
        try item.moveTo(ClinicalOps.AlertNoticeStatus.inReview)
        #expect(item.status == ClinicalOps.AlertNoticeStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAlertNotice("code-143", name: "name-204")
        item.status = ClinicalOps.AlertNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertNoticeStatus.`open`) }
    }
}
