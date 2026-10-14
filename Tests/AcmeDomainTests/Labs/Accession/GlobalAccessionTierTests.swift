@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalAccessionTierTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalAccessionTier("code-413", title: "title-261")
        #expect(item.status == Labs.GlobalAccessionTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newGlobalAccessionTier("code-413", title: "title-261")
        try item.moveTo(Labs.GlobalAccessionTierStatus.running)
        #expect(item.status == Labs.GlobalAccessionTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalAccessionTier("code-413", title: "title-261")
        item.status = Labs.GlobalAccessionTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalAccessionTierStatus.new) }
    }
}
