@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newResultTemplate("code-202", name: "name-467")
        #expect(item.status == Labs.ResultTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newResultTemplate("code-202", name: "name-467")
        try item.moveTo(Labs.ResultTemplateStatus.scheduled)
        #expect(item.status == Labs.ResultTemplateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newResultTemplate("code-202", name: "name-467")
        item.status = Labs.ResultTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultTemplateStatus.planned) }
    }
}
