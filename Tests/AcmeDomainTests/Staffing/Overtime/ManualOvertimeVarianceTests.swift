@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeVarianceTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        #expect(item.status == Staffing.ManualOvertimeVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        try item.moveTo(Staffing.ManualOvertimeVarianceStatus.granted)
        #expect(item.status == Staffing.ManualOvertimeVarianceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        item.status = Staffing.ManualOvertimeVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualOvertimeVarianceStatus.requested) }
    }
}
