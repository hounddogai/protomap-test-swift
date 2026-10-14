@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramVarianceTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newLegacyProgramVariance("code-983", title: "title-805")
        #expect(item.status == CareManagement.LegacyProgramVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newLegacyProgramVariance("code-983", title: "title-805")
        try item.moveTo(CareManagement.LegacyProgramVarianceStatus.pending)
        #expect(item.status == CareManagement.LegacyProgramVarianceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newLegacyProgramVariance("code-983", title: "title-805")
        item.status = CareManagement.LegacyProgramVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyProgramVarianceStatus.draft) }
    }
}
