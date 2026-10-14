@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTargetTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newLenientCensusTarget("code-402", title: "title-105")
        #expect(item.status == BedManagement.LenientCensusTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newLenientCensusTarget("code-402", title: "title-105")
        try item.moveTo(BedManagement.LenientCensusTargetStatus.suspended)
        #expect(item.status == BedManagement.LenientCensusTargetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newLenientCensusTarget("code-402", title: "title-105")
        item.status = BedManagement.LenientCensusTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusTargetStatus.draft) }
    }
}
