@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapBundleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAdaptiveCareGapBundle("code-413", label: "label-329")
        #expect(item.status == CareManagement.AdaptiveCareGapBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newAdaptiveCareGapBundle("code-413", label: "label-329")
        try item.moveTo(CareManagement.AdaptiveCareGapBundleStatus.rejected)
        #expect(item.status == CareManagement.AdaptiveCareGapBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAdaptiveCareGapBundle("code-413", label: "label-329")
        item.status = CareManagement.AdaptiveCareGapBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveCareGapBundleStatus.proposed) }
    }
}
