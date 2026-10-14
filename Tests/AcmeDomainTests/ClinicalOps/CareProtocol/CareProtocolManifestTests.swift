@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolManifestTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolManifest("code-932", name: "name-626")
        #expect(item.status == ClinicalOps.CareProtocolManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newCareProtocolManifest("code-932", name: "name-626")
        try item.moveTo(ClinicalOps.CareProtocolManifestStatus.queued)
        #expect(item.status == ClinicalOps.CareProtocolManifestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolManifest("code-932", name: "name-626")
        item.status = ClinicalOps.CareProtocolManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolManifestStatus.new) }
    }
}
