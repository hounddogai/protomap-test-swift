@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSummaryTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        #expect(item.status == CareManagement.ProgramSummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        try item.moveTo(CareManagement.ProgramSummaryStatus.scheduled)
        #expect(item.status == CareManagement.ProgramSummaryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        item.status = CareManagement.ProgramSummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramSummaryStatus.planned) }
    }
}
