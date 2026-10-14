@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialTierTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newDenialTier("code-93", title: "title-581")
        #expect(item.status == RevenueCycle.DenialTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newDenialTier("code-93", title: "title-581")
        try item.moveTo(RevenueCycle.DenialTierStatus.granted)
        #expect(item.status == RevenueCycle.DenialTierStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newDenialTier("code-93", title: "title-581")
        item.status = RevenueCycle.DenialTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialTierStatus.requested) }
    }
}
