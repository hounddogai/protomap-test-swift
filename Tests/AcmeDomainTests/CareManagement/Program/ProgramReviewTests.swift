@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramReviewTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newProgramReview("code-568", name: "name-897")
        #expect(item.status == CareManagement.ProgramReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newProgramReview("code-568", name: "name-897")
        try item.moveTo(CareManagement.ProgramReviewStatus.resolved)
        #expect(item.status == CareManagement.ProgramReviewStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newProgramReview("code-568", name: "name-897")
        item.status = CareManagement.ProgramReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramReviewStatus.`open`) }
    }
}
