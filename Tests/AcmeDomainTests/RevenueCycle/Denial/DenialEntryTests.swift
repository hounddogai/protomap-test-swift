@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialEntryTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDenialEntry("code-973", title: "title-738")
        #expect(item.status == RevenueCycle.DenialEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newDenialEntry("code-973", title: "title-738")
        try item.moveTo(RevenueCycle.DenialEntryStatus.cancelled)
        #expect(item.status == RevenueCycle.DenialEntryStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDenialEntry("code-973", title: "title-738")
        item.status = RevenueCycle.DenialEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialEntryStatus.planned) }
    }
}
