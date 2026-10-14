@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolLedgerTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolLedger("code-374", name: "name-187")
        #expect(item.status == ClinicalOps.CareProtocolLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newCareProtocolLedger("code-374", name: "name-187")
        try item.moveTo(ClinicalOps.CareProtocolLedgerStatus.scheduled)
        #expect(item.status == ClinicalOps.CareProtocolLedgerStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolLedger("code-374", name: "name-187")
        item.status = ClinicalOps.CareProtocolLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolLedgerStatus.planned) }
    }
}
