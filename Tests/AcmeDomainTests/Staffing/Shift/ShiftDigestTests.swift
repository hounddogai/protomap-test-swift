@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftDigestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftDigest("code-928", label: "label-132")
        #expect(item.status == Staffing.ShiftDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newShiftDigest("code-928", label: "label-132")
        try item.moveTo(Staffing.ShiftDigestStatus.failed)
        #expect(item.status == Staffing.ShiftDigestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftDigest("code-928", label: "label-132")
        item.status = Staffing.ShiftDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftDigestStatus.new) }
    }
}
