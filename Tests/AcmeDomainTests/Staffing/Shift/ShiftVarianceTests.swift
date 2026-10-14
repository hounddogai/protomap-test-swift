@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftVarianceTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftVariance("code-277", title: "title-928")
        #expect(item.status == Staffing.ShiftVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newShiftVariance("code-277", title: "title-928")
        try item.moveTo(Staffing.ShiftVarianceStatus.failed)
        #expect(item.status == Staffing.ShiftVarianceStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftVariance("code-277", title: "title-928")
        item.status = Staffing.ShiftVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftVarianceStatus.new) }
    }
}
