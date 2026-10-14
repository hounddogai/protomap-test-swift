@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftThresholdTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        #expect(item.status == Staffing.StrictShiftThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        try item.moveTo(Staffing.StrictShiftThresholdStatus.inReview)
        #expect(item.status == Staffing.StrictShiftThresholdStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        item.status = Staffing.StrictShiftThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictShiftThresholdStatus.`open`) }
    }
}
