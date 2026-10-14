@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationBundleTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newTieredAuthorizationBundle("code-599", title: "title-734")
        #expect(item.status == RevenueCycle.TieredAuthorizationBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newTieredAuthorizationBundle("code-599", title: "title-734")
        try item.moveTo(RevenueCycle.TieredAuthorizationBundleStatus.closed)
        #expect(item.status == RevenueCycle.TieredAuthorizationBundleStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newTieredAuthorizationBundle("code-599", title: "title-734")
        item.status = RevenueCycle.TieredAuthorizationBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredAuthorizationBundleStatus.draft) }
    }
}
