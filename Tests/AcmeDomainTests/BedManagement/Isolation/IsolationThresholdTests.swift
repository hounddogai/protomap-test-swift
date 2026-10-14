@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationThresholdTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newIsolationThreshold("code-243", name: "name-954")
        #expect(item.status == BedManagement.IsolationThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newIsolationThreshold("code-243", name: "name-954")
        try item.moveTo(BedManagement.IsolationThresholdStatus.inProgress)
        #expect(item.status == BedManagement.IsolationThresholdStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newIsolationThreshold("code-243", name: "name-954")
        item.status = BedManagement.IsolationThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationThresholdStatus.planned) }
    }
}
