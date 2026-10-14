@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramClaimTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newCappedProgramClaim("code-77", title: "title-528")
        #expect(item.status == CareManagement.CappedProgramClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newCappedProgramClaim("code-77", title: "title-528")
        try item.moveTo(CareManagement.CappedProgramClaimStatus.scheduled)
        #expect(item.status == CareManagement.CappedProgramClaimStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newCappedProgramClaim("code-77", title: "title-528")
        item.status = CareManagement.CappedProgramClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedProgramClaimStatus.planned) }
    }
}
