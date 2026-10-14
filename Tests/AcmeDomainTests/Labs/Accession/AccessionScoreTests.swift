@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScoreTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAccessionScore("code-46", title: "title-598")
        #expect(item.status == Labs.AccessionScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newAccessionScore("code-46", title: "title-598")
        try item.moveTo(Labs.AccessionScoreStatus.validated)
        #expect(item.status == Labs.AccessionScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAccessionScore("code-46", title: "title-598")
        item.status = Labs.AccessionScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionScoreStatus.created) }
    }
}
