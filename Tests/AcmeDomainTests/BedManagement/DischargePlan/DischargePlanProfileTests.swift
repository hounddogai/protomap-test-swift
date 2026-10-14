@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProfileTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanProfile("code-473", title: "title-847")
        #expect(item.status == BedManagement.DischargePlanProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newDischargePlanProfile("code-473", title: "title-847")
        try item.moveTo(BedManagement.DischargePlanProfileStatus.pending)
        #expect(item.status == BedManagement.DischargePlanProfileStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanProfile("code-473", title: "title-847")
        item.status = BedManagement.DischargePlanProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanProfileStatus.draft) }
    }
}
