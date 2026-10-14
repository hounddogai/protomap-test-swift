@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeDigestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newOvertimeDigest("code-393", title: "title-884")
        #expect(item.status == Staffing.OvertimeDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newOvertimeDigest("code-393", title: "title-884")
        try item.moveTo(Staffing.OvertimeDigestStatus.queued)
        #expect(item.status == Staffing.OvertimeDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newOvertimeDigest("code-393", title: "title-884")
        item.status = Staffing.OvertimeDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeDigestStatus.new) }
    }
}
