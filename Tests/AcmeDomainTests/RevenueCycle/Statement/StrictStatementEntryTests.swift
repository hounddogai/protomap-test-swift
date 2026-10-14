@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictStatementEntryTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newStrictStatementEntry("code-487", label: "label-637")
        #expect(item.status == RevenueCycle.StrictStatementEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newStrictStatementEntry("code-487", label: "label-637")
        try item.moveTo(RevenueCycle.StrictStatementEntryStatus.granted)
        #expect(item.status == RevenueCycle.StrictStatementEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newStrictStatementEntry("code-487", label: "label-637")
        item.status = RevenueCycle.StrictStatementEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictStatementEntryStatus.requested) }
    }
}
