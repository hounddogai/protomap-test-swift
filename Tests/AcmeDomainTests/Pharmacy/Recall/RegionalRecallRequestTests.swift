@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallRequestTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRegionalRecallRequest("code-460", title: "title-110")
        #expect(item.status == Pharmacy.RegionalRecallRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRegionalRecallRequest("code-460", title: "title-110")
        try item.moveTo(Pharmacy.RegionalRecallRequestStatus.inReview)
        #expect(item.status == Pharmacy.RegionalRecallRequestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRegionalRecallRequest("code-460", title: "title-110")
        item.status = Pharmacy.RegionalRecallRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalRecallRequestStatus.`open`) }
    }
}
