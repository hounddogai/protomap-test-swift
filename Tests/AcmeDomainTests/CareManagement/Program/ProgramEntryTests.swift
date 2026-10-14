@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramEntryTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newProgramEntry("code-714", label: "label-550")
        #expect(item.status == CareManagement.ProgramEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newProgramEntry("code-714", label: "label-550")
        try item.moveTo(CareManagement.ProgramEntryStatus.granted)
        #expect(item.status == CareManagement.ProgramEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newProgramEntry("code-714", label: "label-550")
        item.status = CareManagement.ProgramEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramEntryStatus.requested) }
    }
}
