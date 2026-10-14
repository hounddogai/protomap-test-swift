@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanBatchTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAcuityPlanBatch("code-106", name: "name-211")
        #expect(item.status == Staffing.AcuityPlanBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newAcuityPlanBatch("code-106", name: "name-211")
        try item.moveTo(Staffing.AcuityPlanBatchStatus.done)
        #expect(item.status == Staffing.AcuityPlanBatchStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAcuityPlanBatch("code-106", name: "name-211")
        item.status = Staffing.AcuityPlanBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanBatchStatus.new) }
    }
}
