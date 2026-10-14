@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAssignmentTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAuthorizationAssignment("code-832", name: "name-617")
        #expect(item.status == RevenueCycle.AuthorizationAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newAuthorizationAssignment("code-832", name: "name-617")
        try item.moveTo(RevenueCycle.AuthorizationAssignmentStatus.queued)
        #expect(item.status == RevenueCycle.AuthorizationAssignmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAuthorizationAssignment("code-832", name: "name-617")
        item.status = RevenueCycle.AuthorizationAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationAssignmentStatus.new) }
    }
}
