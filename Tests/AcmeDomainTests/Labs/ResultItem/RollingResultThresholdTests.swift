@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultThresholdTests {
    @Test func startsInProposed() throws {
        let item = Labs.newRollingResultThreshold("code-830", name: "name-196")
        #expect(item.status == Labs.RollingResultThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newRollingResultThreshold("code-830", name: "name-196")
        try item.moveTo(Labs.RollingResultThresholdStatus.approved)
        #expect(item.status == Labs.RollingResultThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newRollingResultThreshold("code-830", name: "name-196")
        item.status = Labs.RollingResultThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingResultThresholdStatus.proposed) }
    }
}
