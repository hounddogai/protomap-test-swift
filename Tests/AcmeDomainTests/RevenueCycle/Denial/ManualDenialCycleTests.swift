@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialCycleTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newManualDenialCycle("code-956", title: "title-471")
        #expect(item.status == RevenueCycle.ManualDenialCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newManualDenialCycle("code-956", title: "title-471")
        try item.moveTo(RevenueCycle.ManualDenialCycleStatus.rejected)
        #expect(item.status == RevenueCycle.ManualDenialCycleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newManualDenialCycle("code-956", title: "title-471")
        item.status = RevenueCycle.ManualDenialCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialCycleStatus.proposed) }
    }
}
