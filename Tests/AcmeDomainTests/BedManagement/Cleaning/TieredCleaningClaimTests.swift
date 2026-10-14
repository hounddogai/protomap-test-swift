@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningClaimTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        #expect(item.status == BedManagement.TieredCleaningClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        try item.moveTo(BedManagement.TieredCleaningClaimStatus.failed)
        #expect(item.status == BedManagement.TieredCleaningClaimStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        item.status = BedManagement.TieredCleaningClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredCleaningClaimStatus.new) }
    }
}
