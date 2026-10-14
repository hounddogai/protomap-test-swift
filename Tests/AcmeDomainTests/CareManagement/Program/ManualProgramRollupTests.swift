@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramRollupTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newManualProgramRollup("code-294", name: "name-256")
        #expect(item.status == CareManagement.ManualProgramRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newManualProgramRollup("code-294", name: "name-256")
        try item.moveTo(CareManagement.ManualProgramRollupStatus.done)
        #expect(item.status == CareManagement.ManualProgramRollupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newManualProgramRollup("code-294", name: "name-256")
        item.status = CareManagement.ManualProgramRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualProgramRollupStatus.new) }
    }
}
