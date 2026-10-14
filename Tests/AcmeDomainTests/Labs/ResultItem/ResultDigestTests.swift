@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultDigestTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newResultDigest("code-175", name: "name-314")
        #expect(item.status == Labs.ResultDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newResultDigest("code-175", name: "name-314")
        try item.moveTo(Labs.ResultDigestStatus.scheduled)
        #expect(item.status == Labs.ResultDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newResultDigest("code-175", name: "name-314")
        item.status = Labs.ResultDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultDigestStatus.planned) }
    }
}
