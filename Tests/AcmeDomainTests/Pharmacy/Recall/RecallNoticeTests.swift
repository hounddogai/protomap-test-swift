@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallNoticeTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallNotice("code-967", title: "title-490")
        #expect(item.status == Pharmacy.RecallNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRecallNotice("code-967", title: "title-490")
        try item.moveTo(Pharmacy.RecallNoticeStatus.inReview)
        #expect(item.status == Pharmacy.RecallNoticeStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallNotice("code-967", title: "title-490")
        item.status = Pharmacy.RecallNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallNoticeStatus.`open`) }
    }
}
