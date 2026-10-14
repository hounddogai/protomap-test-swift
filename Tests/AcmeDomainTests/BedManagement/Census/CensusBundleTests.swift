@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBundleTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCensusBundle("code-727", title: "title-275")
        #expect(item.status == BedManagement.CensusBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newCensusBundle("code-727", title: "title-275")
        try item.moveTo(BedManagement.CensusBundleStatus.pending)
        #expect(item.status == BedManagement.CensusBundleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCensusBundle("code-727", title: "title-275")
        item.status = BedManagement.CensusBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusBundleStatus.draft) }
    }
}
