@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallRecordTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallRecord("code-977", title: "title-319")
        #expect(item.status == Pharmacy.RecallRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRecallRecord("code-977", title: "title-319")
        try item.moveTo(Pharmacy.RecallRecordStatus.approved)
        #expect(item.status == Pharmacy.RecallRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallRecord("code-977", title: "title-319")
        item.status = Pharmacy.RecallRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallRecordStatus.proposed) }
    }
}
