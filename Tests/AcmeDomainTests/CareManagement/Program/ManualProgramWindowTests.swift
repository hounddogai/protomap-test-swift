@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramWindowTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newManualProgramWindow("code-280", title: "title-503")
        #expect(item.status == CareManagement.ManualProgramWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newManualProgramWindow("code-280", title: "title-503")
        try item.moveTo(CareManagement.ManualProgramWindowStatus.pending)
        #expect(item.status == CareManagement.ManualProgramWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newManualProgramWindow("code-280", title: "title-503")
        item.status = CareManagement.ManualProgramWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualProgramWindowStatus.draft) }
    }
}
