@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolManifestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newLenientCareProtocolManifest("code-183", label: "label-792")
        #expect(item.status == ClinicalOps.LenientCareProtocolManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newLenientCareProtocolManifest("code-183", label: "label-792")
        try item.moveTo(ClinicalOps.LenientCareProtocolManifestStatus.approved)
        #expect(item.status == ClinicalOps.LenientCareProtocolManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newLenientCareProtocolManifest("code-183", label: "label-792")
        item.status = ClinicalOps.LenientCareProtocolManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientCareProtocolManifestStatus.proposed) }
    }
}
