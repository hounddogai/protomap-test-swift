@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierRequestTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLenientCourierRequest("code-949", label: "label-922")
        #expect(item.status == Labs.LenientCourierRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newLenientCourierRequest("code-949", label: "label-922")
        try item.moveTo(Labs.LenientCourierRequestStatus.resolved)
        #expect(item.status == Labs.LenientCourierRequestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLenientCourierRequest("code-949", label: "label-922")
        item.status = Labs.LenientCourierRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientCourierRequestStatus.`open`) }
    }
}
