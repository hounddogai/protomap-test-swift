@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultPolicyTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAdaptiveResultPolicy("code-522", label: "label-464")
        #expect(item.status == Labs.AdaptiveResultPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newAdaptiveResultPolicy("code-522", label: "label-464")
        try item.moveTo(Labs.AdaptiveResultPolicyStatus.approved)
        #expect(item.status == Labs.AdaptiveResultPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAdaptiveResultPolicy("code-522", label: "label-464")
        item.status = Labs.AdaptiveResultPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveResultPolicyStatus.proposed) }
    }
}
