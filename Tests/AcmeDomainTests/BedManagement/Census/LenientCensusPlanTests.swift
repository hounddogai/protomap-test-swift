@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusPlanTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLenientCensusPlan("code-549", title: "title-205")
        #expect(item.status == BedManagement.LenientCensusPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newLenientCensusPlan("code-549", title: "title-205")
        try item.moveTo(BedManagement.LenientCensusPlanStatus.scheduled)
        #expect(item.status == BedManagement.LenientCensusPlanStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLenientCensusPlan("code-549", title: "title-205")
        item.status = BedManagement.LenientCensusPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusPlanStatus.planned) }
    }
}
