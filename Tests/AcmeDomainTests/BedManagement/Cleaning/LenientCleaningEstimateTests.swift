@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningEstimateTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLenientCleaningEstimate("code-685", name: "name-574")
        #expect(item.status == BedManagement.LenientCleaningEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newLenientCleaningEstimate("code-685", name: "name-574")
        try item.moveTo(BedManagement.LenientCleaningEstimateStatus.completed)
        #expect(item.status == BedManagement.LenientCleaningEstimateStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLenientCleaningEstimate("code-685", name: "name-574")
        item.status = BedManagement.LenientCleaningEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCleaningEstimateStatus.planned) }
    }
}
