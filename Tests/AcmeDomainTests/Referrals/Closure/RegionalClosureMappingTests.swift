@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureMappingTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newRegionalClosureMapping("code-378", title: "title-748")
        #expect(item.status == Referrals.RegionalClosureMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newRegionalClosureMapping("code-378", title: "title-748")
        try item.moveTo(Referrals.RegionalClosureMappingStatus.resolved)
        #expect(item.status == Referrals.RegionalClosureMappingStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newRegionalClosureMapping("code-378", title: "title-748")
        item.status = Referrals.RegionalClosureMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalClosureMappingStatus.`open`) }
    }
}
