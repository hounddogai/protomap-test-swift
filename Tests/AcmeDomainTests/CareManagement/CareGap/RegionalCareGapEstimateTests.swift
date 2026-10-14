@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapEstimateTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRegionalCareGapEstimate("code-996", label: "label-752")
        #expect(item.status == CareManagement.RegionalCareGapEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newRegionalCareGapEstimate("code-996", label: "label-752")
        try item.moveTo(CareManagement.RegionalCareGapEstimateStatus.queued)
        #expect(item.status == CareManagement.RegionalCareGapEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRegionalCareGapEstimate("code-996", label: "label-752")
        item.status = CareManagement.RegionalCareGapEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalCareGapEstimateStatus.new) }
    }
}
