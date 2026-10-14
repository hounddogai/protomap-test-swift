@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTierTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newRemittanceTier("code-885", title: "title-110")
        #expect(item.status == RevenueCycle.RemittanceTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newRemittanceTier("code-885", title: "title-110")
        try item.moveTo(RevenueCycle.RemittanceTierStatus.pending)
        #expect(item.status == RevenueCycle.RemittanceTierStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newRemittanceTier("code-885", title: "title-110")
        item.status = RevenueCycle.RemittanceTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceTierStatus.draft) }
    }
}
