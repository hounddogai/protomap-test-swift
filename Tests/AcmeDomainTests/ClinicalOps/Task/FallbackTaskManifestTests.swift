@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskManifestTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newFallbackTaskManifest("code-655", name: "name-975")
        #expect(item.status == ClinicalOps.FallbackTaskManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newFallbackTaskManifest("code-655", name: "name-975")
        try item.moveTo(ClinicalOps.FallbackTaskManifestStatus.retired)
        #expect(item.status == ClinicalOps.FallbackTaskManifestStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newFallbackTaskManifest("code-655", name: "name-975")
        item.status = ClinicalOps.FallbackTaskManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackTaskManifestStatus.created) }
    }
}
