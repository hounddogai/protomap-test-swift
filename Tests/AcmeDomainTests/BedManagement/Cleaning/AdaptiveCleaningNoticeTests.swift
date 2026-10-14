@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningNoticeTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newAdaptiveCleaningNotice("code-494", title: "title-211")
        #expect(item.status == BedManagement.AdaptiveCleaningNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newAdaptiveCleaningNotice("code-494", title: "title-211")
        try item.moveTo(BedManagement.AdaptiveCleaningNoticeStatus.revoked)
        #expect(item.status == BedManagement.AdaptiveCleaningNoticeStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newAdaptiveCleaningNotice("code-494", title: "title-211")
        item.status = BedManagement.AdaptiveCleaningNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningNoticeStatus.requested) }
    }
}
