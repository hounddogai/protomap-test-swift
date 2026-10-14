@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPendingResultPreference("code-48", label: "label-230")
        #expect(item.status == Labs.PendingResultPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPendingResultPreference("code-48", label: "label-230")
        try item.moveTo(Labs.PendingResultPreferenceStatus.approved)
        #expect(item.status == Labs.PendingResultPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPendingResultPreference("code-48", label: "label-230")
        item.status = Labs.PendingResultPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultPreferenceStatus.proposed) }
    }
}
