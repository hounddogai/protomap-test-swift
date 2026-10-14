@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardMappingTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardMapping("code-575", label: "label-935")
        #expect(item.status == BedManagement.BedBoardMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = BedManagement.newBedBoardMapping("code-575", label: "label-935")
        try item.moveTo(BedManagement.BedBoardMappingStatus.cancelled)
        #expect(item.status == BedManagement.BedBoardMappingStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardMapping("code-575", label: "label-935")
        item.status = BedManagement.BedBoardMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardMappingStatus.planned) }
    }
}
