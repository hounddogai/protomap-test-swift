@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTargetTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRemittanceTarget("code-417", label: "label-79")
        #expect(item.status == RevenueCycle.RemittanceTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRemittanceTarget("code-417", label: "label-79")
        try item.moveTo(RevenueCycle.RemittanceTargetStatus.granted)
        #expect(item.status == RevenueCycle.RemittanceTargetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRemittanceTarget("code-417", label: "label-79")
        item.status = RevenueCycle.RemittanceTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceTargetStatus.requested) }
    }
}
