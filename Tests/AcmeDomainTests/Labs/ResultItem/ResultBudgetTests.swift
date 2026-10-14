@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBudgetTests {
    @Test func startsInNew() throws {
        let item = Labs.newResultBudget("code-268", title: "title-558")
        #expect(item.status == Labs.ResultBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newResultBudget("code-268", title: "title-558")
        try item.moveTo(Labs.ResultBudgetStatus.done)
        #expect(item.status == Labs.ResultBudgetStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newResultBudget("code-268", title: "title-558")
        item.status = Labs.ResultBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultBudgetStatus.new) }
    }
}
