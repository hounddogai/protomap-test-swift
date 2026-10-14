@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBundleTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDenialBundle("code-659", name: "name-773")
        #expect(item.status == RevenueCycle.DenialBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newDenialBundle("code-659", name: "name-773")
        try item.moveTo(RevenueCycle.DenialBundleStatus.stopped)
        #expect(item.status == RevenueCycle.DenialBundleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDenialBundle("code-659", name: "name-773")
        item.status = RevenueCycle.DenialBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialBundleStatus.idle) }
    }
}
