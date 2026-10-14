@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallRecordTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        #expect(item.status == Pharmacy.LegacyRecallRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        try item.moveTo(Pharmacy.LegacyRecallRecordStatus.inProgress)
        #expect(item.status == Pharmacy.LegacyRecallRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        item.status = Pharmacy.LegacyRecallRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyRecallRecordStatus.planned) }
    }
}
