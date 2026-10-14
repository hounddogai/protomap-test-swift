@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTierTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusTier("code-995", name: "name-41")
        #expect(item.status == BedManagement.CensusTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newCensusTier("code-995", name: "name-41")
        try item.moveTo(BedManagement.CensusTierStatus.ready)
        #expect(item.status == BedManagement.CensusTierStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusTier("code-995", name: "name-41")
        item.status = BedManagement.CensusTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusTierStatus.idle) }
    }
}
