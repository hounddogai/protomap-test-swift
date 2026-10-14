@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMappingTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationMapping("code-972", label: "label-815")
        #expect(item.status == RevenueCycle.AuthorizationMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newAuthorizationMapping("code-972", label: "label-815")
        try item.moveTo(RevenueCycle.AuthorizationMappingStatus.pending)
        #expect(item.status == RevenueCycle.AuthorizationMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationMapping("code-972", label: "label-815")
        item.status = RevenueCycle.AuthorizationMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationMappingStatus.draft) }
    }
}
