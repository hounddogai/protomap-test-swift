@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRollupTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newDenialRollup("code-646", name: "name-587")
        #expect(item.status == RevenueCycle.DenialRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newDenialRollup("code-646", name: "name-587")
        try item.moveTo(RevenueCycle.DenialRollupStatus.suspended)
        #expect(item.status == RevenueCycle.DenialRollupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newDenialRollup("code-646", name: "name-587")
        item.status = RevenueCycle.DenialRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialRollupStatus.draft) }
    }
}
