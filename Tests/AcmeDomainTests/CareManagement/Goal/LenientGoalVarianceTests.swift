@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientGoalVarianceTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newLenientGoalVariance("code-908", name: "name-693")
        #expect(item.status == CareManagement.LenientGoalVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newLenientGoalVariance("code-908", name: "name-693")
        try item.moveTo(CareManagement.LenientGoalVarianceStatus.reopened)
        #expect(item.status == CareManagement.LenientGoalVarianceStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newLenientGoalVariance("code-908", name: "name-693")
        item.status = CareManagement.LenientGoalVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientGoalVarianceStatus.`open`) }
    }
}
