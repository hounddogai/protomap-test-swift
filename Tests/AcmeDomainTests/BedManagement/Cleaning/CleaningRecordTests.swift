@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRecordTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCleaningRecord("code-859", name: "name-695")
        #expect(item.status == BedManagement.CleaningRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newCleaningRecord("code-859", name: "name-695")
        try item.moveTo(BedManagement.CleaningRecordStatus.rejected)
        #expect(item.status == BedManagement.CleaningRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCleaningRecord("code-859", name: "name-695")
        item.status = BedManagement.CleaningRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningRecordStatus.proposed) }
    }
}
