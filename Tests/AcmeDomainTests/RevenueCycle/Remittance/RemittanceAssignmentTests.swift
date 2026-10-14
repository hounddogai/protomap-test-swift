@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAssignmentTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceAssignment("code-486", name: "name-21")
        #expect(item.status == RevenueCycle.RemittanceAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRemittanceAssignment("code-486", name: "name-21")
        try item.moveTo(RevenueCycle.RemittanceAssignmentStatus.validated)
        #expect(item.status == RevenueCycle.RemittanceAssignmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceAssignment("code-486", name: "name-21")
        item.status = RevenueCycle.RemittanceAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceAssignmentStatus.created) }
    }
}
