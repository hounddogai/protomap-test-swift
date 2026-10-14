@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalDischargePlanProfileTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newRegionalDischargePlanProfile("code-925", title: "title-428")
        #expect(item.status == BedManagement.RegionalDischargePlanProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newRegionalDischargePlanProfile("code-925", title: "title-428")
        try item.moveTo(BedManagement.RegionalDischargePlanProfileStatus.pending)
        #expect(item.status == BedManagement.RegionalDischargePlanProfileStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newRegionalDischargePlanProfile("code-925", title: "title-428")
        item.status = BedManagement.RegionalDischargePlanProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalDischargePlanProfileStatus.draft) }
    }
}
