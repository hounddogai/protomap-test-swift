@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeOverrideTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPendingReferenceRangeOverride("code-65", label: "label-265")
        #expect(item.status == Labs.PendingReferenceRangeOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newPendingReferenceRangeOverride("code-65", label: "label-265")
        try item.moveTo(Labs.PendingReferenceRangeOverrideStatus.granted)
        #expect(item.status == Labs.PendingReferenceRangeOverrideStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPendingReferenceRangeOverride("code-65", label: "label-265")
        item.status = Labs.PendingReferenceRangeOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingReferenceRangeOverrideStatus.requested) }
    }
}
