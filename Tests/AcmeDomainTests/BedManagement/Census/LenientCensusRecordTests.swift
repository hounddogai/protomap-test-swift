@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusRecordTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLenientCensusRecord("code-199", label: "label-570")
        #expect(item.status == BedManagement.LenientCensusRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = BedManagement.newLenientCensusRecord("code-199", label: "label-570")
        try item.moveTo(BedManagement.LenientCensusRecordStatus.cancelled)
        #expect(item.status == BedManagement.LenientCensusRecordStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLenientCensusRecord("code-199", label: "label-570")
        item.status = BedManagement.LenientCensusRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusRecordStatus.planned) }
    }
}
