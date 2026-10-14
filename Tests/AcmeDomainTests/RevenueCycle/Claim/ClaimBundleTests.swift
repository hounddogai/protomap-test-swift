@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBundleTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newClaimBundle("code-870", title: "title-175")
        #expect(item.status == RevenueCycle.ClaimBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newClaimBundle("code-870", title: "title-175")
        try item.moveTo(RevenueCycle.ClaimBundleStatus.granted)
        #expect(item.status == RevenueCycle.ClaimBundleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newClaimBundle("code-870", title: "title-175")
        item.status = RevenueCycle.ClaimBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimBundleStatus.requested) }
    }
}
