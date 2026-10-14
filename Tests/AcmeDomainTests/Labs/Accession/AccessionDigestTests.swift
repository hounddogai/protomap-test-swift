@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionDigestTests {
    @Test func startsInNew() throws {
        let item = Labs.newAccessionDigest("code-631", title: "title-523")
        #expect(item.status == Labs.AccessionDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newAccessionDigest("code-631", title: "title-523")
        try item.moveTo(Labs.AccessionDigestStatus.running)
        #expect(item.status == Labs.AccessionDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAccessionDigest("code-631", title: "title-523")
        item.status = Labs.AccessionDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionDigestStatus.new) }
    }
}
