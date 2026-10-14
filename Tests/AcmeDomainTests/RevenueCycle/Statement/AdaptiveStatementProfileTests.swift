@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementProfileTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAdaptiveStatementProfile("code-154", label: "label-191")
        #expect(item.status == RevenueCycle.AdaptiveStatementProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAdaptiveStatementProfile("code-154", label: "label-191")
        try item.moveTo(RevenueCycle.AdaptiveStatementProfileStatus.approved)
        #expect(item.status == RevenueCycle.AdaptiveStatementProfileStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAdaptiveStatementProfile("code-154", label: "label-191")
        item.status = RevenueCycle.AdaptiveStatementProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementProfileStatus.proposed) }
    }
}
