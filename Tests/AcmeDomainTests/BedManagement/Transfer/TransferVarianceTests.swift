@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferVarianceTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTransferVariance("code-456", title: "title-922")
        #expect(item.status == BedManagement.TransferVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newTransferVariance("code-456", title: "title-922")
        try item.moveTo(BedManagement.TransferVarianceStatus.queued)
        #expect(item.status == BedManagement.TransferVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTransferVariance("code-456", title: "title-922")
        item.status = BedManagement.TransferVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferVarianceStatus.new) }
    }
}
