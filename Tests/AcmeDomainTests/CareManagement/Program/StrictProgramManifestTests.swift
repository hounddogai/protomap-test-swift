@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictProgramManifestTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newStrictProgramManifest("code-340", label: "label-543")
        #expect(item.status == CareManagement.StrictProgramManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = CareManagement.newStrictProgramManifest("code-340", label: "label-543")
        try item.moveTo(CareManagement.StrictProgramManifestStatus.cancelled)
        #expect(item.status == CareManagement.StrictProgramManifestStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newStrictProgramManifest("code-340", label: "label-543")
        item.status = CareManagement.StrictProgramManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictProgramManifestStatus.planned) }
    }
}
