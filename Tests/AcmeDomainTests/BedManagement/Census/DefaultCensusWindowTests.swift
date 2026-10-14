@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCensusWindowTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDefaultCensusWindow("code-166", label: "label-66")
        #expect(item.status == BedManagement.DefaultCensusWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newDefaultCensusWindow("code-166", label: "label-66")
        try item.moveTo(BedManagement.DefaultCensusWindowStatus.suspended)
        #expect(item.status == BedManagement.DefaultCensusWindowStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDefaultCensusWindow("code-166", label: "label-66")
        item.status = BedManagement.DefaultCensusWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCensusWindowStatus.draft) }
    }
}
