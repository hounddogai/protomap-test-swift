@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapOverrideTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newAdaptiveCareGapOverride("code-868", label: "label-915")
        #expect(item.status == CareManagement.AdaptiveCareGapOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newAdaptiveCareGapOverride("code-868", label: "label-915")
        try item.moveTo(CareManagement.AdaptiveCareGapOverrideStatus.queued)
        #expect(item.status == CareManagement.AdaptiveCareGapOverrideStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newAdaptiveCareGapOverride("code-868", label: "label-915")
        item.status = CareManagement.AdaptiveCareGapOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveCareGapOverrideStatus.new) }
    }
}
