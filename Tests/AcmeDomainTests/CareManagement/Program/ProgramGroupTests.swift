@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramGroupTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newProgramGroup("code-665", label: "label-436")
        #expect(item.status == CareManagement.ProgramGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newProgramGroup("code-665", label: "label-436")
        try item.moveTo(CareManagement.ProgramGroupStatus.granted)
        #expect(item.status == CareManagement.ProgramGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newProgramGroup("code-665", label: "label-436")
        item.status = CareManagement.ProgramGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramGroupStatus.requested) }
    }
}
