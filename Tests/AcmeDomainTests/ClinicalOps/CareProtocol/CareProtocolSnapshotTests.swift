@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolSnapshotTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolSnapshot("code-271", name: "name-948")
        #expect(item.status == ClinicalOps.CareProtocolSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newCareProtocolSnapshot("code-271", name: "name-948")
        try item.moveTo(ClinicalOps.CareProtocolSnapshotStatus.warming)
        #expect(item.status == ClinicalOps.CareProtocolSnapshotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolSnapshot("code-271", name: "name-948")
        item.status = ClinicalOps.CareProtocolSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolSnapshotStatus.idle) }
    }
}
