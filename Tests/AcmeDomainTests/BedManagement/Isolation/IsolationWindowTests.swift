@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationWindowTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newIsolationWindow("code-701", label: "label-685")
        #expect(item.status == BedManagement.IsolationWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newIsolationWindow("code-701", label: "label-685")
        try item.moveTo(BedManagement.IsolationWindowStatus.inProgress)
        #expect(item.status == BedManagement.IsolationWindowStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newIsolationWindow("code-701", label: "label-685")
        item.status = BedManagement.IsolationWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationWindowStatus.planned) }
    }
}
