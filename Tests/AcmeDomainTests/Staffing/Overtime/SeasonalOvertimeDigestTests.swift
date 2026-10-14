@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalOvertimeDigestTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newSeasonalOvertimeDigest("code-788", name: "name-810")
        #expect(item.status == Staffing.SeasonalOvertimeDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newSeasonalOvertimeDigest("code-788", name: "name-810")
        try item.moveTo(Staffing.SeasonalOvertimeDigestStatus.rejected)
        #expect(item.status == Staffing.SeasonalOvertimeDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newSeasonalOvertimeDigest("code-788", name: "name-810")
        item.status = Staffing.SeasonalOvertimeDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalOvertimeDigestStatus.proposed) }
    }
}
