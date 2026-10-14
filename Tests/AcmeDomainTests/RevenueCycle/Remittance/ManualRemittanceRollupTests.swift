@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRollupTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newManualRemittanceRollup("code-780", name: "name-550")
        #expect(item.status == RevenueCycle.ManualRemittanceRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newManualRemittanceRollup("code-780", name: "name-550")
        try item.moveTo(RevenueCycle.ManualRemittanceRollupStatus.validated)
        #expect(item.status == RevenueCycle.ManualRemittanceRollupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newManualRemittanceRollup("code-780", name: "name-550")
        item.status = RevenueCycle.ManualRemittanceRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualRemittanceRollupStatus.created) }
    }
}
