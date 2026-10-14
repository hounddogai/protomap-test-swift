@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreTierTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newWeightedRiskScoreTier("code-613", name: "name-24")
        #expect(item.status == CareManagement.WeightedRiskScoreTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newWeightedRiskScoreTier("code-613", name: "name-24")
        try item.moveTo(CareManagement.WeightedRiskScoreTierStatus.granted)
        #expect(item.status == CareManagement.WeightedRiskScoreTierStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newWeightedRiskScoreTier("code-613", name: "name-24")
        item.status = CareManagement.WeightedRiskScoreTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedRiskScoreTierStatus.requested) }
    }
}
