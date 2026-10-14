@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationDigestTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStrictAuthorizationDigest("code-365", name: "name-956")
        #expect(item.status == RevenueCycle.StrictAuthorizationDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationDigest("code-365", name: "name-956")
        try item.moveTo(RevenueCycle.StrictAuthorizationDigestStatus.retired)
        #expect(item.status == RevenueCycle.StrictAuthorizationDigestStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationDigest("code-365", name: "name-956")
        item.status = RevenueCycle.StrictAuthorizationDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictAuthorizationDigestStatus.created) }
    }
}
