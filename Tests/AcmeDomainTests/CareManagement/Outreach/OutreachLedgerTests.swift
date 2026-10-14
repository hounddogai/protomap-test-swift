@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachLedgerTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newOutreachLedger("code-700", label: "label-361")
        #expect(item.status == CareManagement.OutreachLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newOutreachLedger("code-700", label: "label-361")
        try item.moveTo(CareManagement.OutreachLedgerStatus.validated)
        #expect(item.status == CareManagement.OutreachLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newOutreachLedger("code-700", label: "label-361")
        item.status = CareManagement.OutreachLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachLedgerStatus.created) }
    }
}
