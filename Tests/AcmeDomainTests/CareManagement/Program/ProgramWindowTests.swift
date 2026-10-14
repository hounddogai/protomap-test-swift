@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramWindowTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newProgramWindow("code-51", name: "name-143")
        #expect(item.status == CareManagement.ProgramWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newProgramWindow("code-51", name: "name-143")
        try item.moveTo(CareManagement.ProgramWindowStatus.running)
        #expect(item.status == CareManagement.ProgramWindowStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newProgramWindow("code-51", name: "name-143")
        item.status = CareManagement.ProgramWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramWindowStatus.new) }
    }
}
