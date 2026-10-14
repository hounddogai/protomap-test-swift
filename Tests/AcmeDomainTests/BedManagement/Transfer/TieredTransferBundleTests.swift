@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredTransferBundleTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newTieredTransferBundle("code-746", label: "label-31")
        #expect(item.status == BedManagement.TieredTransferBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newTieredTransferBundle("code-746", label: "label-31")
        try item.moveTo(BedManagement.TieredTransferBundleStatus.withdrawn)
        #expect(item.status == BedManagement.TieredTransferBundleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newTieredTransferBundle("code-746", label: "label-31")
        item.status = BedManagement.TieredTransferBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredTransferBundleStatus.proposed) }
    }
}
