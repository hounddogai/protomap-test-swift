@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningVarianceTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCleaningVariance("code-557", label: "label-637")
        #expect(item.status == BedManagement.CleaningVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newCleaningVariance("code-557", label: "label-637")
        try item.moveTo(BedManagement.CleaningVarianceStatus.inProgress)
        #expect(item.status == BedManagement.CleaningVarianceStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCleaningVariance("code-557", label: "label-637")
        item.status = BedManagement.CleaningVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningVarianceStatus.planned) }
    }
}
