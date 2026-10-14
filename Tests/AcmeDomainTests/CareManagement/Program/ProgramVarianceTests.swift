@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramVarianceTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramVariance("code-979", label: "label-37")
        #expect(item.status == CareManagement.ProgramVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newProgramVariance("code-979", label: "label-37")
        try item.moveTo(CareManagement.ProgramVarianceStatus.active)
        #expect(item.status == CareManagement.ProgramVarianceStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramVariance("code-979", label: "label-37")
        item.status = CareManagement.ProgramVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramVarianceStatus.draft) }
    }
}
