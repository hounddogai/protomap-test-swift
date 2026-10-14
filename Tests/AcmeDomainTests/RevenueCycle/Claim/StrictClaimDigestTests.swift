@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimDigestTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newStrictClaimDigest("code-630", name: "name-755")
        #expect(item.status == RevenueCycle.StrictClaimDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newStrictClaimDigest("code-630", name: "name-755")
        try item.moveTo(RevenueCycle.StrictClaimDigestStatus.running)
        #expect(item.status == RevenueCycle.StrictClaimDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newStrictClaimDigest("code-630", name: "name-755")
        item.status = RevenueCycle.StrictClaimDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictClaimDigestStatus.new) }
    }
}
