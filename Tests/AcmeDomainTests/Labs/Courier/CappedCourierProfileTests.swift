@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierProfileTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCappedCourierProfile("code-445", label: "label-662")
        #expect(item.status == Labs.CappedCourierProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCappedCourierProfile("code-445", label: "label-662")
        try item.moveTo(Labs.CappedCourierProfileStatus.validated)
        #expect(item.status == Labs.CappedCourierProfileStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCappedCourierProfile("code-445", label: "label-662")
        item.status = Labs.CappedCourierProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedCourierProfileStatus.created) }
    }
}
