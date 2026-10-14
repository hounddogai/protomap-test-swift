@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDraftTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationDraft("code-208", name: "name-52")
        #expect(item.status == BedManagement.IsolationDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newIsolationDraft("code-208", name: "name-52")
        try item.moveTo(BedManagement.IsolationDraftStatus.warming)
        #expect(item.status == BedManagement.IsolationDraftStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationDraft("code-208", name: "name-52")
        item.status = BedManagement.IsolationDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationDraftStatus.idle) }
    }
}
