@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementTierTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newManualStatementTier("code-259", label: "label-411")
        #expect(item.status == RevenueCycle.ManualStatementTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newManualStatementTier("code-259", label: "label-411")
        try item.moveTo(RevenueCycle.ManualStatementTierStatus.validated)
        #expect(item.status == RevenueCycle.ManualStatementTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newManualStatementTier("code-259", label: "label-411")
        item.status = RevenueCycle.ManualStatementTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualStatementTierStatus.created) }
    }
}
