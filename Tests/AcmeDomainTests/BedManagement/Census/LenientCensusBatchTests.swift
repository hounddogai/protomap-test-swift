@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusBatchTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newLenientCensusBatch("code-944", name: "name-465")
        #expect(item.status == BedManagement.LenientCensusBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newLenientCensusBatch("code-944", name: "name-465")
        try item.moveTo(BedManagement.LenientCensusBatchStatus.pending)
        #expect(item.status == BedManagement.LenientCensusBatchStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newLenientCensusBatch("code-944", name: "name-465")
        item.status = BedManagement.LenientCensusBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusBatchStatus.draft) }
    }
}
