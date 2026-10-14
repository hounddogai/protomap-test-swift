@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierDraftTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierDraft("code-118", name: "name-961")
        #expect(item.status == Labs.CourierDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newCourierDraft("code-118", name: "name-961")
        try item.moveTo(Labs.CourierDraftStatus.rejected)
        #expect(item.status == Labs.CourierDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierDraft("code-118", name: "name-961")
        item.status = Labs.CourierDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierDraftStatus.proposed) }
    }
}
