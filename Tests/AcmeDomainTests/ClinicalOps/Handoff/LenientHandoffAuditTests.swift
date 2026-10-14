@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientHandoffAuditTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newLenientHandoffAudit("code-129", title: "title-582")
        #expect(item.status == ClinicalOps.LenientHandoffAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newLenientHandoffAudit("code-129", title: "title-582")
        try item.moveTo(ClinicalOps.LenientHandoffAuditStatus.running)
        #expect(item.status == ClinicalOps.LenientHandoffAuditStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newLenientHandoffAudit("code-129", title: "title-582")
        item.status = ClinicalOps.LenientHandoffAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientHandoffAuditStatus.new) }
    }
}
