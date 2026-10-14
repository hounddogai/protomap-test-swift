@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTierTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newResultTier("code-918", label: "label-494")
        #expect(item.status == Labs.ResultTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newResultTier("code-918", label: "label-494")
        try item.moveTo(Labs.ResultTierStatus.scheduled)
        #expect(item.status == Labs.ResultTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newResultTier("code-918", label: "label-494")
        item.status = Labs.ResultTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultTierStatus.planned) }
    }
}
