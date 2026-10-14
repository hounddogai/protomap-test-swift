@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRecordTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationRecord("code-81", label: "label-120")
        #expect(item.status == BedManagement.IsolationRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newIsolationRecord("code-81", label: "label-120")
        try item.moveTo(BedManagement.IsolationRecordStatus.suspended)
        #expect(item.status == BedManagement.IsolationRecordStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationRecord("code-81", label: "label-120")
        item.status = BedManagement.IsolationRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationRecordStatus.draft) }
    }
}
