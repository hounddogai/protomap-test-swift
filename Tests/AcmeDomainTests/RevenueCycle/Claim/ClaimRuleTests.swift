@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRuleTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newClaimRule("code-32", title: "title-958")
        #expect(item.status == RevenueCycle.ClaimRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newClaimRule("code-32", title: "title-958")
        try item.moveTo(RevenueCycle.ClaimRuleStatus.failed)
        #expect(item.status == RevenueCycle.ClaimRuleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newClaimRule("code-32", title: "title-958")
        item.status = RevenueCycle.ClaimRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimRuleStatus.new) }
    }
}
