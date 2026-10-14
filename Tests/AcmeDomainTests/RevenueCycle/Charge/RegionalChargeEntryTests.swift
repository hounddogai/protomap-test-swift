@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeEntryTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRegionalChargeEntry("code-216", label: "label-822")
        #expect(item.status == RevenueCycle.RegionalChargeEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRegionalChargeEntry("code-216", label: "label-822")
        try item.moveTo(RevenueCycle.RegionalChargeEntryStatus.granted)
        #expect(item.status == RevenueCycle.RegionalChargeEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRegionalChargeEntry("code-216", label: "label-822")
        item.status = RevenueCycle.RegionalChargeEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalChargeEntryStatus.requested) }
    }
}
