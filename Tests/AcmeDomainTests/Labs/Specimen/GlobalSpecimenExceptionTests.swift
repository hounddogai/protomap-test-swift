@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenExceptionTests {
    @Test func startsInDraft() throws {
        let item = Labs.newGlobalSpecimenException("code-699", title: "title-856")
        #expect(item.status == Labs.GlobalSpecimenExceptionStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newGlobalSpecimenException("code-699", title: "title-856")
        try item.moveTo(Labs.GlobalSpecimenExceptionStatus.suspended)
        #expect(item.status == Labs.GlobalSpecimenExceptionStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newGlobalSpecimenException("code-699", title: "title-856")
        item.status = Labs.GlobalSpecimenExceptionStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalSpecimenExceptionStatus.draft) }
    }
}
