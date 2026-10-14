@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingFloatPoolDraftTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPendingFloatPoolDraft("code-602", name: "name-45")
        #expect(item.status == Staffing.PendingFloatPoolDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newPendingFloatPoolDraft("code-602", name: "name-45")
        try item.moveTo(Staffing.PendingFloatPoolDraftStatus.approved)
        #expect(item.status == Staffing.PendingFloatPoolDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPendingFloatPoolDraft("code-602", name: "name-45")
        item.status = Staffing.PendingFloatPoolDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingFloatPoolDraftStatus.proposed) }
    }
}
