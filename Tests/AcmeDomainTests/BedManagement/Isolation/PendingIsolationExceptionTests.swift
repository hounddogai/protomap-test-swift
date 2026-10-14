@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationExceptionTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newPendingIsolationException("code-661", label: "label-787")
        #expect(item.status == BedManagement.PendingIsolationExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newPendingIsolationException("code-661", label: "label-787")
        try item.moveTo(BedManagement.PendingIsolationExceptionStatus.inProgress)
        #expect(item.status == BedManagement.PendingIsolationExceptionStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newPendingIsolationException("code-661", label: "label-787")
        item.status = BedManagement.PendingIsolationExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingIsolationExceptionStatus.planned) }
    }
}
