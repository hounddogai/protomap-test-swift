@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotManifestTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newPendingSlotManifest("code-754", label: "label-929")
        #expect(item.status == Referrals.PendingSlotManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newPendingSlotManifest("code-754", label: "label-929")
        try item.moveTo(Referrals.PendingSlotManifestStatus.warming)
        #expect(item.status == Referrals.PendingSlotManifestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newPendingSlotManifest("code-754", label: "label-929")
        item.status = Referrals.PendingSlotManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingSlotManifestStatus.idle) }
    }
}
