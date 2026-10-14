@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackProgramVarianceTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        #expect(item.status == CareManagement.FallbackProgramVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        try item.moveTo(CareManagement.FallbackProgramVarianceStatus.inReview)
        #expect(item.status == CareManagement.FallbackProgramVarianceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        item.status = CareManagement.FallbackProgramVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackProgramVarianceStatus.`open`) }
    }
}
