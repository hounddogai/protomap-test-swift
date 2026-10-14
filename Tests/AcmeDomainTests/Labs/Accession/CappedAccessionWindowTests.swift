@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionWindowTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        #expect(item.status == Labs.CappedAccessionWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        try item.moveTo(Labs.CappedAccessionWindowStatus.validated)
        #expect(item.status == Labs.CappedAccessionWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        item.status = Labs.CappedAccessionWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedAccessionWindowStatus.created) }
    }
}
