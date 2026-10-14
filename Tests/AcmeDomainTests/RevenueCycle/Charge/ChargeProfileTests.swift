@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProfileTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeProfile("code-930", label: "label-402")
        #expect(item.status == RevenueCycle.ChargeProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newChargeProfile("code-930", label: "label-402")
        try item.moveTo(RevenueCycle.ChargeProfileStatus.inProgress)
        #expect(item.status == RevenueCycle.ChargeProfileStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeProfile("code-930", label: "label-402")
        item.status = RevenueCycle.ChargeProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeProfileStatus.planned) }
    }
}
