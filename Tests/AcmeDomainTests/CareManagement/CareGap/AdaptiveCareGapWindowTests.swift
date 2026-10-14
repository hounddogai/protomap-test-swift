@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapWindowTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newAdaptiveCareGapWindow("code-352", title: "title-96")
        #expect(item.status == CareManagement.AdaptiveCareGapWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newAdaptiveCareGapWindow("code-352", title: "title-96")
        try item.moveTo(CareManagement.AdaptiveCareGapWindowStatus.pending)
        #expect(item.status == CareManagement.AdaptiveCareGapWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newAdaptiveCareGapWindow("code-352", title: "title-96")
        item.status = CareManagement.AdaptiveCareGapWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveCareGapWindowStatus.draft) }
    }
}
