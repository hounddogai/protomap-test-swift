@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientRiskScorePreferenceTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        #expect(item.status == CareManagement.LenientRiskScorePreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        try item.moveTo(CareManagement.LenientRiskScorePreferenceStatus.resolved)
        #expect(item.status == CareManagement.LenientRiskScorePreferenceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newLenientRiskScorePreference("code-880", title: "title-78")
        item.status = CareManagement.LenientRiskScorePreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientRiskScorePreferenceStatus.`open`) }
    }
}
