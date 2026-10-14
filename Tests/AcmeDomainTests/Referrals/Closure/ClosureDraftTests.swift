@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureDraftTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newClosureDraft("code-222", name: "name-597")
        #expect(item.status == Referrals.ClosureDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newClosureDraft("code-222", name: "name-597")
        try item.moveTo(Referrals.ClosureDraftStatus.resolved)
        #expect(item.status == Referrals.ClosureDraftStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newClosureDraft("code-222", name: "name-597")
        item.status = Referrals.ClosureDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureDraftStatus.`open`) }
    }
}
