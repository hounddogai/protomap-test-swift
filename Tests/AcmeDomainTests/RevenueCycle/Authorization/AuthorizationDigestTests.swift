@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationDigestTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newAuthorizationDigest("code-993", name: "name-145")
        #expect(item.status == RevenueCycle.AuthorizationDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newAuthorizationDigest("code-993", name: "name-145")
        try item.moveTo(RevenueCycle.AuthorizationDigestStatus.warming)
        #expect(item.status == RevenueCycle.AuthorizationDigestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newAuthorizationDigest("code-993", name: "name-145")
        item.status = RevenueCycle.AuthorizationDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationDigestStatus.idle) }
    }
}
