@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelDigestTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newRegionalPanelDigest("code-148", title: "title-871")
        #expect(item.status == Labs.RegionalPanelDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newRegionalPanelDigest("code-148", title: "title-871")
        try item.moveTo(Labs.RegionalPanelDigestStatus.scheduled)
        #expect(item.status == Labs.RegionalPanelDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newRegionalPanelDigest("code-148", title: "title-871")
        item.status = Labs.RegionalPanelDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalPanelDigestStatus.planned) }
    }
}
