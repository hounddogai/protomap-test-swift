@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualTransferEstimateTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newManualTransferEstimate("code-737", name: "name-785")
        #expect(item.status == BedManagement.ManualTransferEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newManualTransferEstimate("code-737", name: "name-785")
        try item.moveTo(BedManagement.ManualTransferEstimateStatus.revoked)
        #expect(item.status == BedManagement.ManualTransferEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newManualTransferEstimate("code-737", name: "name-785")
        item.status = BedManagement.ManualTransferEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualTransferEstimateStatus.requested) }
    }
}
