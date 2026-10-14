@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeEntryTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newCappedChargeEntry("code-244", title: "title-972")
        #expect(item.status == RevenueCycle.CappedChargeEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newCappedChargeEntry("code-244", title: "title-972")
        try item.moveTo(RevenueCycle.CappedChargeEntryStatus.scheduled)
        #expect(item.status == RevenueCycle.CappedChargeEntryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newCappedChargeEntry("code-244", title: "title-972")
        item.status = RevenueCycle.CappedChargeEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedChargeEntryStatus.planned) }
    }
}
