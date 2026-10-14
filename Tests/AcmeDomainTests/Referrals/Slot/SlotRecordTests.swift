@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotRecordTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSlotRecord("code-864", title: "title-702")
        #expect(item.status == Referrals.SlotRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newSlotRecord("code-864", title: "title-702")
        try item.moveTo(Referrals.SlotRecordStatus.warming)
        #expect(item.status == Referrals.SlotRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSlotRecord("code-864", title: "title-702")
        item.status = Referrals.SlotRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotRecordStatus.idle) }
    }
}
