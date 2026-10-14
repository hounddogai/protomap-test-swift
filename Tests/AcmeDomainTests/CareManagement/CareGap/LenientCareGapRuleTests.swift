@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapRuleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newLenientCareGapRule("code-913", name: "name-748")
        #expect(item.status == CareManagement.LenientCareGapRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newLenientCareGapRule("code-913", name: "name-748")
        try item.moveTo(CareManagement.LenientCareGapRuleStatus.withdrawn)
        #expect(item.status == CareManagement.LenientCareGapRuleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newLenientCareGapRule("code-913", name: "name-748")
        item.status = CareManagement.LenientCareGapRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientCareGapRuleStatus.proposed) }
    }
}
