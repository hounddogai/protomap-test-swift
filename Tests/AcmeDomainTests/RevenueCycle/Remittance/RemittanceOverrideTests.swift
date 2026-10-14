@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceOverrideTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceOverride("code-200", label: "label-344")
        #expect(item.status == RevenueCycle.RemittanceOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRemittanceOverride("code-200", label: "label-344")
        try item.moveTo(RevenueCycle.RemittanceOverrideStatus.warming)
        #expect(item.status == RevenueCycle.RemittanceOverrideStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceOverride("code-200", label: "label-344")
        item.status = RevenueCycle.RemittanceOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceOverrideStatus.idle) }
    }
}
