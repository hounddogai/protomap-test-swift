@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationEntryTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLegacyAuthorizationEntry("code-710", label: "label-629")
        #expect(item.status == RevenueCycle.LegacyAuthorizationEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newLegacyAuthorizationEntry("code-710", label: "label-629")
        try item.moveTo(RevenueCycle.LegacyAuthorizationEntryStatus.retired)
        #expect(item.status == RevenueCycle.LegacyAuthorizationEntryStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLegacyAuthorizationEntry("code-710", label: "label-629")
        item.status = RevenueCycle.LegacyAuthorizationEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyAuthorizationEntryStatus.created) }
    }
}
