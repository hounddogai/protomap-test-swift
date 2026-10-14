@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreItemTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAdaptiveRiskScoreItem("code-860", name: "name-803")
        #expect(item.status == CareManagement.AdaptiveRiskScoreItemStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newAdaptiveRiskScoreItem("code-860", name: "name-803")
        try item.moveTo(CareManagement.AdaptiveRiskScoreItemStatus.validated)
        #expect(item.status == CareManagement.AdaptiveRiskScoreItemStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAdaptiveRiskScoreItem("code-860", name: "name-803")
        item.status = CareManagement.AdaptiveRiskScoreItemStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveRiskScoreItemStatus.created) }
    }
}
