@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBatchTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusBatch("code-720", name: "name-380")
        #expect(item.status == BedManagement.CensusBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newCensusBatch("code-720", name: "name-380")
        try item.moveTo(BedManagement.CensusBatchStatus.failed)
        #expect(item.status == BedManagement.CensusBatchStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusBatch("code-720", name: "name-380")
        item.status = BedManagement.CensusBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusBatchStatus.new) }
    }
}
