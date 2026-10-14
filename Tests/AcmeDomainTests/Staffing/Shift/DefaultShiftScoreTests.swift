@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftScoreTests {
    @Test func startsInNew() throws {
        let item = Staffing.newDefaultShiftScore("code-828", name: "name-838")
        #expect(item.status == Staffing.DefaultShiftScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newDefaultShiftScore("code-828", name: "name-838")
        try item.moveTo(Staffing.DefaultShiftScoreStatus.queued)
        #expect(item.status == Staffing.DefaultShiftScoreStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newDefaultShiftScore("code-828", name: "name-838")
        item.status = Staffing.DefaultShiftScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultShiftScoreStatus.new) }
    }
}
