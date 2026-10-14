@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceAssignmentTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRollingRemittanceAssignment("code-598", name: "name-310")
        #expect(item.status == RevenueCycle.RollingRemittanceAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newRollingRemittanceAssignment("code-598", name: "name-310")
        try item.moveTo(RevenueCycle.RollingRemittanceAssignmentStatus.published)
        #expect(item.status == RevenueCycle.RollingRemittanceAssignmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRollingRemittanceAssignment("code-598", name: "name-310")
        item.status = RevenueCycle.RollingRemittanceAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingRemittanceAssignmentStatus.created) }
    }
}
