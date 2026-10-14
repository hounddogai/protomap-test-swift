@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAuditTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        #expect(item.status == CareManagement.CareGapAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        try item.moveTo(CareManagement.CareGapAuditStatus.resolved)
        #expect(item.status == CareManagement.CareGapAuditStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        item.status = CareManagement.CareGapAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapAuditStatus.`open`) }
    }
}
