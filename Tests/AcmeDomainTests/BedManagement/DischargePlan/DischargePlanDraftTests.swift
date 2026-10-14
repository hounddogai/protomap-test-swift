@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanDraftTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanDraft("code-346", title: "title-94")
        #expect(item.status == BedManagement.DischargePlanDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newDischargePlanDraft("code-346", title: "title-94")
        try item.moveTo(BedManagement.DischargePlanDraftStatus.ready)
        #expect(item.status == BedManagement.DischargePlanDraftStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanDraft("code-346", title: "title-94")
        item.status = BedManagement.DischargePlanDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanDraftStatus.idle) }
    }
}
