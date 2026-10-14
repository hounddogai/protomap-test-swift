@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMetricTests {
    @Test func startsInProposed() throws {
        let item = Labs.newResultMetric("code-337", name: "name-188")
        #expect(item.status == Labs.ResultMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newResultMetric("code-337", name: "name-188")
        try item.moveTo(Labs.ResultMetricStatus.withdrawn)
        #expect(item.status == Labs.ResultMetricStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newResultMetric("code-337", name: "name-188")
        item.status = Labs.ResultMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultMetricStatus.proposed) }
    }
}
