@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProfileTests {
    @Test func startsInCreated() throws {
        let item = Labs.newReferenceRangeProfile("code-172", name: "name-88")
        #expect(item.status == Labs.ReferenceRangeProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newReferenceRangeProfile("code-172", name: "name-88")
        try item.moveTo(Labs.ReferenceRangeProfileStatus.validated)
        #expect(item.status == Labs.ReferenceRangeProfileStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newReferenceRangeProfile("code-172", name: "name-88")
        item.status = Labs.ReferenceRangeProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeProfileStatus.created) }
    }
}
