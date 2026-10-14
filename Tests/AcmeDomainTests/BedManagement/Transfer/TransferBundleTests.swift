@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBundleTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newTransferBundle("code-913", name: "name-314")
        #expect(item.status == BedManagement.TransferBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newTransferBundle("code-913", name: "name-314")
        try item.moveTo(BedManagement.TransferBundleStatus.warming)
        #expect(item.status == BedManagement.TransferBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newTransferBundle("code-913", name: "name-314")
        item.status = BedManagement.TransferBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferBundleStatus.idle) }
    }
}
