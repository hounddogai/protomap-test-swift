@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDigestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newDenialDigest("code-587", title: "title-759")
        #expect(item.status == RevenueCycle.DenialDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newDenialDigest("code-587", title: "title-759")
        try item.moveTo(RevenueCycle.DenialDigestStatus.active)
        #expect(item.status == RevenueCycle.DenialDigestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newDenialDigest("code-587", title: "title-759")
        item.status = RevenueCycle.DenialDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialDigestStatus.draft) }
    }
}
