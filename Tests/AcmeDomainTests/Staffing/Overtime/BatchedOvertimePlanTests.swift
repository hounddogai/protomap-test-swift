@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimePlanTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        #expect(item.status == Staffing.BatchedOvertimePlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        try item.moveTo(Staffing.BatchedOvertimePlanStatus.closed)
        #expect(item.status == Staffing.BatchedOvertimePlanStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        item.status = Staffing.BatchedOvertimePlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedOvertimePlanStatus.draft) }
    }
}
