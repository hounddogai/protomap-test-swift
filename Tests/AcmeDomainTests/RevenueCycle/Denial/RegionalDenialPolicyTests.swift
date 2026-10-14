@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialPolicyTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRegionalDenialPolicy("code-465", title: "title-46")
        #expect(item.status == RevenueCycle.RegionalDenialPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = RevenueCycle.newRegionalDenialPolicy("code-465", title: "title-46")
        try item.moveTo(RevenueCycle.RegionalDenialPolicyStatus.expired)
        #expect(item.status == RevenueCycle.RegionalDenialPolicyStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRegionalDenialPolicy("code-465", title: "title-46")
        item.status = RevenueCycle.RegionalDenialPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalDenialPolicyStatus.requested) }
    }
}
