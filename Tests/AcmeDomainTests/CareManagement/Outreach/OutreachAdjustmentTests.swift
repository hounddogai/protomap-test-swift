@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newOutreachAdjustment("code-543", title: "title-834")
        #expect(item.status == CareManagement.OutreachAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = CareManagement.newOutreachAdjustment("code-543", title: "title-834")
        try item.moveTo(CareManagement.OutreachAdjustmentStatus.closed)
        #expect(item.status == CareManagement.OutreachAdjustmentStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newOutreachAdjustment("code-543", title: "title-834")
        item.status = CareManagement.OutreachAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachAdjustmentStatus.draft) }
    }
}
