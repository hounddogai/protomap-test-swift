@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferEstimateTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newTransferEstimate("code-564", label: "label-990")
        #expect(item.status == BedManagement.TransferEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newTransferEstimate("code-564", label: "label-990")
        try item.moveTo(BedManagement.TransferEstimateStatus.draining)
        #expect(item.status == BedManagement.TransferEstimateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newTransferEstimate("code-564", label: "label-990")
        item.status = BedManagement.TransferEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferEstimateStatus.idle) }
    }
}
