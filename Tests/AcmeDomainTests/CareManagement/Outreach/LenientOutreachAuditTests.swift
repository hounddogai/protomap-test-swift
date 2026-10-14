@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachAuditTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        #expect(item.status == CareManagement.LenientOutreachAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        try item.moveTo(CareManagement.LenientOutreachAuditStatus.granted)
        #expect(item.status == CareManagement.LenientOutreachAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        item.status = CareManagement.LenientOutreachAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientOutreachAuditStatus.requested) }
    }
}
