@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpMappingTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLenientFollowUpMapping("code-300", label: "label-930")
        #expect(item.status == Referrals.LenientFollowUpMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newLenientFollowUpMapping("code-300", label: "label-930")
        try item.moveTo(Referrals.LenientFollowUpMappingStatus.archived)
        #expect(item.status == Referrals.LenientFollowUpMappingStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLenientFollowUpMapping("code-300", label: "label-930")
        item.status = Referrals.LenientFollowUpMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientFollowUpMappingStatus.`open`) }
    }
}
