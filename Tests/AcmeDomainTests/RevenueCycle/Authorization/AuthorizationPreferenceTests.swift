@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPreferenceTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAuthorizationPreference("code-803", label: "label-311")
        #expect(item.status == RevenueCycle.AuthorizationPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAuthorizationPreference("code-803", label: "label-311")
        try item.moveTo(RevenueCycle.AuthorizationPreferenceStatus.approved)
        #expect(item.status == RevenueCycle.AuthorizationPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAuthorizationPreference("code-803", label: "label-311")
        item.status = RevenueCycle.AuthorizationPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationPreferenceStatus.proposed) }
    }
}
