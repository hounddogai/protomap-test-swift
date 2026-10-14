@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRollupTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramRollup("code-321", label: "label-879")
        #expect(item.status == CareManagement.ProgramRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newProgramRollup("code-321", label: "label-879")
        try item.moveTo(CareManagement.ProgramRollupStatus.active)
        #expect(item.status == CareManagement.ProgramRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramRollup("code-321", label: "label-879")
        item.status = CareManagement.ProgramRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramRollupStatus.draft) }
    }
}
