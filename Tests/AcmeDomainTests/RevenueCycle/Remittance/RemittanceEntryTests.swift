@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEntryTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newRemittanceEntry("code-81", name: "name-149")
        #expect(item.status == RevenueCycle.RemittanceEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newRemittanceEntry("code-81", name: "name-149")
        try item.moveTo(RevenueCycle.RemittanceEntryStatus.rejected)
        #expect(item.status == RevenueCycle.RemittanceEntryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newRemittanceEntry("code-81", name: "name-149")
        item.status = RevenueCycle.RemittanceEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceEntryStatus.proposed) }
    }
}
