@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultMetricTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLenientResultMetric("code-132", name: "name-568")
        #expect(item.status == Labs.LenientResultMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newLenientResultMetric("code-132", name: "name-568")
        try item.moveTo(Labs.LenientResultMetricStatus.resolved)
        #expect(item.status == Labs.LenientResultMetricStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLenientResultMetric("code-132", name: "name-568")
        item.status = Labs.LenientResultMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientResultMetricStatus.`open`) }
    }
}
