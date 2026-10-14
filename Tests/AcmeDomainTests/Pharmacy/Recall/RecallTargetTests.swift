@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallTargetTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallTarget("code-785", name: "name-235")
        #expect(item.status == Pharmacy.RecallTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRecallTarget("code-785", name: "name-235")
        try item.moveTo(Pharmacy.RecallTargetStatus.inReview)
        #expect(item.status == Pharmacy.RecallTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallTarget("code-785", name: "name-235")
        item.status = Pharmacy.RecallTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallTargetStatus.`open`) }
    }
}
