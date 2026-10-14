@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationDraftTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newRegionalIsolationDraft("code-893", name: "name-70")
        #expect(item.status == BedManagement.RegionalIsolationDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newRegionalIsolationDraft("code-893", name: "name-70")
        try item.moveTo(BedManagement.RegionalIsolationDraftStatus.approved)
        #expect(item.status == BedManagement.RegionalIsolationDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newRegionalIsolationDraft("code-893", name: "name-70")
        item.status = BedManagement.RegionalIsolationDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalIsolationDraftStatus.proposed) }
    }
}
