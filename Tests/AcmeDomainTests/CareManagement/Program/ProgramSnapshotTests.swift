@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSnapshotTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newProgramSnapshot("code-229", label: "label-668")
        #expect(item.status == CareManagement.ProgramSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newProgramSnapshot("code-229", label: "label-668")
        try item.moveTo(CareManagement.ProgramSnapshotStatus.granted)
        #expect(item.status == CareManagement.ProgramSnapshotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newProgramSnapshot("code-229", label: "label-668")
        item.status = CareManagement.ProgramSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramSnapshotStatus.requested) }
    }
}
