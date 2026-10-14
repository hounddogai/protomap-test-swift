@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationEntryTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStrictAuthorizationEntry("code-513", label: "label-897")
        #expect(item.status == RevenueCycle.StrictAuthorizationEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationEntry("code-513", label: "label-897")
        try item.moveTo(RevenueCycle.StrictAuthorizationEntryStatus.retired)
        #expect(item.status == RevenueCycle.StrictAuthorizationEntryStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationEntry("code-513", label: "label-897")
        item.status = RevenueCycle.StrictAuthorizationEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictAuthorizationEntryStatus.created) }
    }
}
