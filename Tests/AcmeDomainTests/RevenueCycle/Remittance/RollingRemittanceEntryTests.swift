@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEntryTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRollingRemittanceEntry("code-227", name: "name-82")
        #expect(item.status == RevenueCycle.RollingRemittanceEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newRollingRemittanceEntry("code-227", name: "name-82")
        try item.moveTo(RevenueCycle.RollingRemittanceEntryStatus.done)
        #expect(item.status == RevenueCycle.RollingRemittanceEntryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRollingRemittanceEntry("code-227", name: "name-82")
        item.status = RevenueCycle.RollingRemittanceEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingRemittanceEntryStatus.new) }
    }
}
