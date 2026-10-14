@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachTierTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAdaptiveOutreachTier("code-111", title: "title-196")
        #expect(item.status == CareManagement.AdaptiveOutreachTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newAdaptiveOutreachTier("code-111", title: "title-196")
        try item.moveTo(CareManagement.AdaptiveOutreachTierStatus.warming)
        #expect(item.status == CareManagement.AdaptiveOutreachTierStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAdaptiveOutreachTier("code-111", title: "title-196")
        item.status = CareManagement.AdaptiveOutreachTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveOutreachTierStatus.idle) }
    }
}
