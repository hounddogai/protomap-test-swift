@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimGroupTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newTieredClaimGroup("code-612", title: "title-351")
        #expect(item.status == RevenueCycle.TieredClaimGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newTieredClaimGroup("code-612", title: "title-351")
        try item.moveTo(RevenueCycle.TieredClaimGroupStatus.failed)
        #expect(item.status == RevenueCycle.TieredClaimGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newTieredClaimGroup("code-612", title: "title-351")
        item.status = RevenueCycle.TieredClaimGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimGroupStatus.new) }
    }
}
