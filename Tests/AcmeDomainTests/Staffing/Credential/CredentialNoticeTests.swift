@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialNoticeTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialNotice("code-747", title: "title-690")
        #expect(item.status == Staffing.CredentialNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newCredentialNotice("code-747", title: "title-690")
        try item.moveTo(Staffing.CredentialNoticeStatus.reopened)
        #expect(item.status == Staffing.CredentialNoticeStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialNotice("code-747", title: "title-690")
        item.status = Staffing.CredentialNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialNoticeStatus.`open`) }
    }
}
