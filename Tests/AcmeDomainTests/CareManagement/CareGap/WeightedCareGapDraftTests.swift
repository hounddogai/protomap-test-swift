@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapDraftTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newWeightedCareGapDraft("code-108", title: "title-709")
        #expect(item.status == CareManagement.WeightedCareGapDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newWeightedCareGapDraft("code-108", title: "title-709")
        try item.moveTo(CareManagement.WeightedCareGapDraftStatus.done)
        #expect(item.status == CareManagement.WeightedCareGapDraftStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newWeightedCareGapDraft("code-108", title: "title-709")
        item.status = CareManagement.WeightedCareGapDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedCareGapDraftStatus.new) }
    }
}
