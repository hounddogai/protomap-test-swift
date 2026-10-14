@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimBundleTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDefaultClaimBundle("code-852", title: "title-115")
        #expect(item.status == RevenueCycle.DefaultClaimBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newDefaultClaimBundle("code-852", title: "title-115")
        try item.moveTo(RevenueCycle.DefaultClaimBundleStatus.warming)
        #expect(item.status == RevenueCycle.DefaultClaimBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDefaultClaimBundle("code-852", title: "title-115")
        item.status = RevenueCycle.DefaultClaimBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultClaimBundleStatus.idle) }
    }
}
