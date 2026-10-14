@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingManifestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newDefaultRoundingManifest("code-959", name: "name-841")
        #expect(item.status == ClinicalOps.DefaultRoundingManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newDefaultRoundingManifest("code-959", name: "name-841")
        try item.moveTo(ClinicalOps.DefaultRoundingManifestStatus.rejected)
        #expect(item.status == ClinicalOps.DefaultRoundingManifestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newDefaultRoundingManifest("code-959", name: "name-841")
        item.status = ClinicalOps.DefaultRoundingManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultRoundingManifestStatus.proposed) }
    }
}
