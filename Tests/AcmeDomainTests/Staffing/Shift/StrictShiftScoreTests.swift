@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftScoreTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newStrictShiftScore("code-633", title: "title-645")
        #expect(item.status == Staffing.StrictShiftScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newStrictShiftScore("code-633", title: "title-645")
        try item.moveTo(Staffing.StrictShiftScoreStatus.active)
        #expect(item.status == Staffing.StrictShiftScoreStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newStrictShiftScore("code-633", title: "title-645")
        item.status = Staffing.StrictShiftScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictShiftScoreStatus.draft) }
    }
}
