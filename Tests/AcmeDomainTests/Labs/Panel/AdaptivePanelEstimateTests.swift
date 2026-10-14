@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelEstimateTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAdaptivePanelEstimate("code-687", label: "label-306")
        #expect(item.status == Labs.AdaptivePanelEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newAdaptivePanelEstimate("code-687", label: "label-306")
        try item.moveTo(Labs.AdaptivePanelEstimateStatus.expired)
        #expect(item.status == Labs.AdaptivePanelEstimateStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAdaptivePanelEstimate("code-687", label: "label-306")
        item.status = Labs.AdaptivePanelEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptivePanelEstimateStatus.requested) }
    }
}
