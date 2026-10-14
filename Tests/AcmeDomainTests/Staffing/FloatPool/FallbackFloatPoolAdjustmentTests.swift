@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFallbackFloatPoolAdjustment("code-786", label: "label-187")
        #expect(item.status == Staffing.FallbackFloatPoolAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newFallbackFloatPoolAdjustment("code-786", label: "label-187")
        try item.moveTo(Staffing.FallbackFloatPoolAdjustmentStatus.scheduled)
        #expect(item.status == Staffing.FallbackFloatPoolAdjustmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFallbackFloatPoolAdjustment("code-786", label: "label-187")
        item.status = Staffing.FallbackFloatPoolAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackFloatPoolAdjustmentStatus.planned) }
    }
}
