@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierExceptionTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCourierException("code-137", title: "title-437")
        #expect(item.status == Labs.CourierExceptionStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newCourierException("code-137", title: "title-437")
        try item.moveTo(Labs.CourierExceptionStatus.active)
        #expect(item.status == Labs.CourierExceptionStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCourierException("code-137", title: "title-437")
        item.status = Labs.CourierExceptionStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierExceptionStatus.draft) }
    }
}
