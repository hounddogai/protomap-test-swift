@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newLegacyResultVariance("code-302", title: "title-740")
        #expect(item.status == Labs.LegacyResultVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newLegacyResultVariance("code-302", title: "title-740")
        try item.moveTo(Labs.LegacyResultVarianceStatus.scheduled)
        #expect(item.status == Labs.LegacyResultVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newLegacyResultVariance("code-302", title: "title-740")
        item.status = Labs.LegacyResultVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyResultVarianceStatus.planned) }
    }
}
