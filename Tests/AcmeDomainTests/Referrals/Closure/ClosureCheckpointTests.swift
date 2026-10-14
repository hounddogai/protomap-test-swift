@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCheckpointTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newClosureCheckpoint("code-944", label: "label-237")
        #expect(item.status == Referrals.ClosureCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newClosureCheckpoint("code-944", label: "label-237")
        try item.moveTo(Referrals.ClosureCheckpointStatus.resolved)
        #expect(item.status == Referrals.ClosureCheckpointStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newClosureCheckpoint("code-944", label: "label-237")
        item.status = Referrals.ClosureCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureCheckpointStatus.`open`) }
    }
}
