@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapTargetTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newLenientCareGapTarget("code-789", label: "label-183")
        #expect(item.status == CareManagement.LenientCareGapTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newLenientCareGapTarget("code-789", label: "label-183")
        try item.moveTo(CareManagement.LenientCareGapTargetStatus.inProgress)
        #expect(item.status == CareManagement.LenientCareGapTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newLenientCareGapTarget("code-789", label: "label-183")
        item.status = CareManagement.LenientCareGapTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientCareGapTargetStatus.planned) }
    }
}
