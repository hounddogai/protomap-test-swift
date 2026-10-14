@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCensusAgreementTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBatchedCensusAgreement("code-956", name: "name-599")
        #expect(item.status == BedManagement.BatchedCensusAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newBatchedCensusAgreement("code-956", name: "name-599")
        try item.moveTo(BedManagement.BatchedCensusAgreementStatus.draining)
        #expect(item.status == BedManagement.BatchedCensusAgreementStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBatchedCensusAgreement("code-956", name: "name-599")
        item.status = BedManagement.BatchedCensusAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCensusAgreementStatus.idle) }
    }
}
