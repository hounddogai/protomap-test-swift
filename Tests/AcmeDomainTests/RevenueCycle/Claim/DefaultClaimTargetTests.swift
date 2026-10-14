@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimTargetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDefaultClaimTarget("code-204", title: "title-470")
        #expect(item.status == RevenueCycle.DefaultClaimTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newDefaultClaimTarget("code-204", title: "title-470")
        try item.moveTo(RevenueCycle.DefaultClaimTargetStatus.warming)
        #expect(item.status == RevenueCycle.DefaultClaimTargetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDefaultClaimTarget("code-204", title: "title-470")
        item.status = RevenueCycle.DefaultClaimTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultClaimTargetStatus.idle) }
    }
}
