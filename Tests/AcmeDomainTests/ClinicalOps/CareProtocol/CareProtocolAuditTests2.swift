@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAuditTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newCareProtocolAudit("code-901", title: "title-551")
        #expect(item.status == ClinicalOps.CareProtocolAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newCareProtocolAudit("code-901", title: "title-551")
        try item.moveTo(ClinicalOps.CareProtocolAuditStatus.granted)
        #expect(item.status == ClinicalOps.CareProtocolAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newCareProtocolAudit("code-901", title: "title-551")
        item.status = ClinicalOps.CareProtocolAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolAuditStatus.requested) }
    }
}
