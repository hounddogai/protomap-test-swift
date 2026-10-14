@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackDenialPolicyTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newFallbackDenialPolicy("code-457", title: "title-359")
        #expect(item.status == RevenueCycle.FallbackDenialPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newFallbackDenialPolicy("code-457", title: "title-359")
        try item.moveTo(RevenueCycle.FallbackDenialPolicyStatus.published)
        #expect(item.status == RevenueCycle.FallbackDenialPolicyStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newFallbackDenialPolicy("code-457", title: "title-359")
        item.status = RevenueCycle.FallbackDenialPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackDenialPolicyStatus.created) }
    }
}
