@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeProfileTests {
    @Test func startsInRequested() throws {
        let item = Labs.newFallbackReferenceRangeProfile("code-45", label: "label-491")
        #expect(item.status == Labs.FallbackReferenceRangeProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newFallbackReferenceRangeProfile("code-45", label: "label-491")
        try item.moveTo(Labs.FallbackReferenceRangeProfileStatus.granted)
        #expect(item.status == Labs.FallbackReferenceRangeProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newFallbackReferenceRangeProfile("code-45", label: "label-491")
        item.status = Labs.FallbackReferenceRangeProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackReferenceRangeProfileStatus.requested) }
    }
}
