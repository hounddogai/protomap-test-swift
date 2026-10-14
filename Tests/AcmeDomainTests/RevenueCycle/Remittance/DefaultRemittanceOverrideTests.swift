@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceOverrideTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDefaultRemittanceOverride("code-180", name: "name-753")
        #expect(item.status == RevenueCycle.DefaultRemittanceOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newDefaultRemittanceOverride("code-180", name: "name-753")
        try item.moveTo(RevenueCycle.DefaultRemittanceOverrideStatus.approved)
        #expect(item.status == RevenueCycle.DefaultRemittanceOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDefaultRemittanceOverride("code-180", name: "name-753")
        item.status = RevenueCycle.DefaultRemittanceOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultRemittanceOverrideStatus.proposed) }
    }
}
