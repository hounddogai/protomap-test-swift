@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        #expect(item.status == Staffing.FloatPoolAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        try item.moveTo(Staffing.FloatPoolAdjustmentStatus.retired)
        #expect(item.status == Staffing.FloatPoolAdjustmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        item.status = Staffing.FloatPoolAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolAdjustmentStatus.created) }
    }
}
