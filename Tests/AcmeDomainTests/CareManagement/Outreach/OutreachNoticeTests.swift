@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachNoticeTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newOutreachNotice("code-247", label: "label-595")
        #expect(item.status == CareManagement.OutreachNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newOutreachNotice("code-247", label: "label-595")
        try item.moveTo(CareManagement.OutreachNoticeStatus.completed)
        #expect(item.status == CareManagement.OutreachNoticeStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newOutreachNotice("code-247", label: "label-595")
        item.status = CareManagement.OutreachNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachNoticeStatus.planned) }
    }
}
