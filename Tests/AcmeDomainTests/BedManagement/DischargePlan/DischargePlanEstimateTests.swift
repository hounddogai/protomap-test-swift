@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanEstimateTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newDischargePlanEstimate("code-147", label: "label-277")
        #expect(item.status == BedManagement.DischargePlanEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newDischargePlanEstimate("code-147", label: "label-277")
        try item.moveTo(BedManagement.DischargePlanEstimateStatus.scheduled)
        #expect(item.status == BedManagement.DischargePlanEstimateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newDischargePlanEstimate("code-147", label: "label-277")
        item.status = BedManagement.DischargePlanEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanEstimateStatus.planned) }
    }
}
