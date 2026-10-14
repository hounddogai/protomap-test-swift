@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBundleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newShiftBundle("code-583", name: "name-194")
        #expect(item.status == Staffing.ShiftBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newShiftBundle("code-583", name: "name-194")
        try item.moveTo(Staffing.ShiftBundleStatus.reopened)
        #expect(item.status == Staffing.ShiftBundleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newShiftBundle("code-583", name: "name-194")
        item.status = Staffing.ShiftBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftBundleStatus.`open`) }
    }
}
