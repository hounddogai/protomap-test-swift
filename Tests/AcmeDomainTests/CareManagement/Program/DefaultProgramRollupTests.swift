@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramRollupTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newDefaultProgramRollup("code-721", label: "label-930")
        #expect(item.status == CareManagement.DefaultProgramRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newDefaultProgramRollup("code-721", label: "label-930")
        try item.moveTo(CareManagement.DefaultProgramRollupStatus.granted)
        #expect(item.status == CareManagement.DefaultProgramRollupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newDefaultProgramRollup("code-721", label: "label-930")
        item.status = CareManagement.DefaultProgramRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultProgramRollupStatus.requested) }
    }
}
