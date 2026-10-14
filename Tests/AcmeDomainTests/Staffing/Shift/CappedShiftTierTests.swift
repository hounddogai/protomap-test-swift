@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftTierTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCappedShiftTier("code-891", label: "label-446")
        #expect(item.status == Staffing.CappedShiftTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newCappedShiftTier("code-891", label: "label-446")
        try item.moveTo(Staffing.CappedShiftTierStatus.inReview)
        #expect(item.status == Staffing.CappedShiftTierStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCappedShiftTier("code-891", label: "label-446")
        item.status = Staffing.CappedShiftTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedShiftTierStatus.`open`) }
    }
}
