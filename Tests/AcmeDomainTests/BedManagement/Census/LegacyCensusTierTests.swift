@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusTierTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        #expect(item.status == BedManagement.LegacyCensusTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        try item.moveTo(BedManagement.LegacyCensusTierStatus.done)
        #expect(item.status == BedManagement.LegacyCensusTierStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        item.status = BedManagement.LegacyCensusTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusTierStatus.new) }
    }
}
