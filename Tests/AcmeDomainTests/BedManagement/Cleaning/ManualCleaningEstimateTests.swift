@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningEstimateTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newManualCleaningEstimate("code-504", name: "name-301")
        #expect(item.status == BedManagement.ManualCleaningEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = BedManagement.newManualCleaningEstimate("code-504", name: "name-301")
        try item.moveTo(BedManagement.ManualCleaningEstimateStatus.cancelled)
        #expect(item.status == BedManagement.ManualCleaningEstimateStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newManualCleaningEstimate("code-504", name: "name-301")
        item.status = BedManagement.ManualCleaningEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCleaningEstimateStatus.planned) }
    }
}
