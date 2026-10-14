@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBundleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceBundle("code-196", label: "label-975")
        #expect(item.status == RevenueCycle.RemittanceBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newRemittanceBundle("code-196", label: "label-975")
        try item.moveTo(RevenueCycle.RemittanceBundleStatus.scheduled)
        #expect(item.status == RevenueCycle.RemittanceBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceBundle("code-196", label: "label-975")
        item.status = RevenueCycle.RemittanceBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceBundleStatus.planned) }
    }
}
