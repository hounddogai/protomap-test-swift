@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySnapshotTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newEligibilitySnapshot("code-844", label: "label-340")
        #expect(item.status == Referrals.EligibilitySnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newEligibilitySnapshot("code-844", label: "label-340")
        try item.moveTo(Referrals.EligibilitySnapshotStatus.archived)
        #expect(item.status == Referrals.EligibilitySnapshotStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newEligibilitySnapshot("code-844", label: "label-340")
        item.status = Referrals.EligibilitySnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilitySnapshotStatus.`open`) }
    }
}
