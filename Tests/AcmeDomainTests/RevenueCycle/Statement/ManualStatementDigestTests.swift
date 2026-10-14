@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementDigestTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newManualStatementDigest("code-507", name: "name-142")
        #expect(item.status == RevenueCycle.ManualStatementDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newManualStatementDigest("code-507", name: "name-142")
        try item.moveTo(RevenueCycle.ManualStatementDigestStatus.running)
        #expect(item.status == RevenueCycle.ManualStatementDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newManualStatementDigest("code-507", name: "name-142")
        item.status = RevenueCycle.ManualStatementDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualStatementDigestStatus.new) }
    }
}
