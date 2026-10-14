@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramClaimTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramClaim("code-279", label: "label-53")
        #expect(item.status == CareManagement.ProgramClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newProgramClaim("code-279", label: "label-53")
        try item.moveTo(CareManagement.ProgramClaimStatus.suspended)
        #expect(item.status == CareManagement.ProgramClaimStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramClaim("code-279", label: "label-53")
        item.status = CareManagement.ProgramClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramClaimStatus.draft) }
    }
}
