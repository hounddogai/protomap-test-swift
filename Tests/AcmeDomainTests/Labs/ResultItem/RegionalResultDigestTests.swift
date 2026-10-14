@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultDigestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newRegionalResultDigest("code-406", label: "label-858")
        #expect(item.status == Labs.RegionalResultDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newRegionalResultDigest("code-406", label: "label-858")
        try item.moveTo(Labs.RegionalResultDigestStatus.rejected)
        #expect(item.status == Labs.RegionalResultDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newRegionalResultDigest("code-406", label: "label-858")
        item.status = Labs.RegionalResultDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalResultDigestStatus.proposed) }
    }
}
