@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetScheduleTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetSchedule("code-122", title: "title-160")
        #expect(item.status == ClinicalOps.OrderSetScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newOrderSetSchedule("code-122", title: "title-160")
        try item.moveTo(ClinicalOps.OrderSetScheduleStatus.suspended)
        #expect(item.status == ClinicalOps.OrderSetScheduleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetSchedule("code-122", title: "title-160")
        item.status = ClinicalOps.OrderSetScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetScheduleStatus.draft) }
    }
}
