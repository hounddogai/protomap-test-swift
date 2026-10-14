@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallRequestTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newPendingRecallRequest("code-56", title: "title-483")
        #expect(item.status == Pharmacy.PendingRecallRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newPendingRecallRequest("code-56", title: "title-483")
        try item.moveTo(Pharmacy.PendingRecallRequestStatus.inReview)
        #expect(item.status == Pharmacy.PendingRecallRequestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newPendingRecallRequest("code-56", title: "title-483")
        item.status = Pharmacy.PendingRecallRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallRequestStatus.`open`) }
    }
}
