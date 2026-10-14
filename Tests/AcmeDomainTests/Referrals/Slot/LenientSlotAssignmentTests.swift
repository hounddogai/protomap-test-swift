@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLenientSlotAssignment("code-739", name: "name-943")
        #expect(item.status == Referrals.LenientSlotAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newLenientSlotAssignment("code-739", name: "name-943")
        try item.moveTo(Referrals.LenientSlotAssignmentStatus.published)
        #expect(item.status == Referrals.LenientSlotAssignmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLenientSlotAssignment("code-739", name: "name-943")
        item.status = Referrals.LenientSlotAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientSlotAssignmentStatus.created) }
    }
}
