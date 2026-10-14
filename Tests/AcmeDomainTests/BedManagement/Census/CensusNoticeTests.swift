@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusNoticeTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusNotice("code-856", title: "title-509")
        #expect(item.status == BedManagement.CensusNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newCensusNotice("code-856", title: "title-509")
        try item.moveTo(BedManagement.CensusNoticeStatus.draining)
        #expect(item.status == BedManagement.CensusNoticeStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusNotice("code-856", title: "title-509")
        item.status = BedManagement.CensusNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusNoticeStatus.idle) }
    }
}
