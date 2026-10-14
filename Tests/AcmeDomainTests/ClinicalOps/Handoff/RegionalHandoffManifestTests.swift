@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffManifestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRegionalHandoffManifest("code-806", label: "label-190")
        #expect(item.status == ClinicalOps.RegionalHandoffManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRegionalHandoffManifest("code-806", label: "label-190")
        try item.moveTo(ClinicalOps.RegionalHandoffManifestStatus.approved)
        #expect(item.status == ClinicalOps.RegionalHandoffManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRegionalHandoffManifest("code-806", label: "label-190")
        item.status = ClinicalOps.RegionalHandoffManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalHandoffManifestStatus.proposed) }
    }
}
