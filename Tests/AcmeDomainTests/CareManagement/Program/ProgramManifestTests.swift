@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramManifestTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newProgramManifest("code-640", name: "name-615")
        #expect(item.status == CareManagement.ProgramManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newProgramManifest("code-640", name: "name-615")
        try item.moveTo(CareManagement.ProgramManifestStatus.completed)
        #expect(item.status == CareManagement.ProgramManifestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newProgramManifest("code-640", name: "name-615")
        item.status = CareManagement.ProgramManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramManifestStatus.planned) }
    }
}
