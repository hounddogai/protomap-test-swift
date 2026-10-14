@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedAlertWindowTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCappedAlertWindow("code-87", label: "label-810")
        #expect(item.status == ClinicalOps.CappedAlertWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newCappedAlertWindow("code-87", label: "label-810")
        try item.moveTo(ClinicalOps.CappedAlertWindowStatus.inReview)
        #expect(item.status == ClinicalOps.CappedAlertWindowStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCappedAlertWindow("code-87", label: "label-810")
        item.status = ClinicalOps.CappedAlertWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedAlertWindowStatus.`open`) }
    }
}
