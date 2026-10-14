@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAuditTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceAudit("code-469", label: "label-349")
        #expect(item.status == RevenueCycle.RemittanceAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRemittanceAudit("code-469", label: "label-349")
        try item.moveTo(RevenueCycle.RemittanceAuditStatus.validated)
        #expect(item.status == RevenueCycle.RemittanceAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceAudit("code-469", label: "label-349")
        item.status = RevenueCycle.RemittanceAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceAuditStatus.created) }
    }
}
