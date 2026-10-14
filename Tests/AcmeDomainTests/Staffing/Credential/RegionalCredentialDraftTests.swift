@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialDraftTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        #expect(item.status == Staffing.RegionalCredentialDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        try item.moveTo(Staffing.RegionalCredentialDraftStatus.resolved)
        #expect(item.status == Staffing.RegionalCredentialDraftStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        item.status = Staffing.RegionalCredentialDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalCredentialDraftStatus.`open`) }
    }
}
