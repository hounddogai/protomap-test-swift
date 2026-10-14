@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationAssignmentTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newFallbackAuthorizationAssignment("code-427", title: "title-108")
        #expect(item.status == RevenueCycle.FallbackAuthorizationAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newFallbackAuthorizationAssignment("code-427", title: "title-108")
        try item.moveTo(RevenueCycle.FallbackAuthorizationAssignmentStatus.retired)
        #expect(item.status == RevenueCycle.FallbackAuthorizationAssignmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newFallbackAuthorizationAssignment("code-427", title: "title-108")
        item.status = RevenueCycle.FallbackAuthorizationAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackAuthorizationAssignmentStatus.created) }
    }
}
