@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkTemplateTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newBatchedNetworkTemplate("code-277", label: "label-452")
        #expect(item.status == Referrals.BatchedNetworkTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newBatchedNetworkTemplate("code-277", label: "label-452")
        try item.moveTo(Referrals.BatchedNetworkTemplateStatus.ready)
        #expect(item.status == Referrals.BatchedNetworkTemplateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newBatchedNetworkTemplate("code-277", label: "label-452")
        item.status = Referrals.BatchedNetworkTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedNetworkTemplateStatus.idle) }
    }
}
