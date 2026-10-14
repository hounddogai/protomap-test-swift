@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientAuthorizationDigestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newLenientAuthorizationDigest("code-437", label: "label-71")
        #expect(item.status == RevenueCycle.LenientAuthorizationDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newLenientAuthorizationDigest("code-437", label: "label-71")
        try item.moveTo(RevenueCycle.LenientAuthorizationDigestStatus.resolved)
        #expect(item.status == RevenueCycle.LenientAuthorizationDigestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newLenientAuthorizationDigest("code-437", label: "label-71")
        item.status = RevenueCycle.LenientAuthorizationDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientAuthorizationDigestStatus.`open`) }
    }
}
