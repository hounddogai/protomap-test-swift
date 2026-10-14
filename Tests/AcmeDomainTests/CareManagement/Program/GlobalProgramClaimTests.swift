@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramClaimTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGlobalProgramClaim("code-711", title: "title-221")
        #expect(item.status == CareManagement.GlobalProgramClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newGlobalProgramClaim("code-711", title: "title-221")
        try item.moveTo(CareManagement.GlobalProgramClaimStatus.done)
        #expect(item.status == CareManagement.GlobalProgramClaimStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGlobalProgramClaim("code-711", title: "title-221")
        item.status = CareManagement.GlobalProgramClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalProgramClaimStatus.new) }
    }
}
