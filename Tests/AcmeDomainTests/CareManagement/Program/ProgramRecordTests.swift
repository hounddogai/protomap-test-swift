@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRecordTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newProgramRecord("code-37", label: "label-989")
        #expect(item.status == CareManagement.ProgramRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newProgramRecord("code-37", label: "label-989")
        try item.moveTo(CareManagement.ProgramRecordStatus.draining)
        #expect(item.status == CareManagement.ProgramRecordStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newProgramRecord("code-37", label: "label-989")
        item.status = CareManagement.ProgramRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramRecordStatus.idle) }
    }
}
