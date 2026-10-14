@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedRemittanceAuditTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newCappedRemittanceAudit("code-881", label: "label-519")
        #expect(item.status == RevenueCycle.CappedRemittanceAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newCappedRemittanceAudit("code-881", label: "label-519")
        try item.moveTo(RevenueCycle.CappedRemittanceAuditStatus.granted)
        #expect(item.status == RevenueCycle.CappedRemittanceAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newCappedRemittanceAudit("code-881", label: "label-519")
        item.status = RevenueCycle.CappedRemittanceAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedRemittanceAuditStatus.requested) }
    }
}
