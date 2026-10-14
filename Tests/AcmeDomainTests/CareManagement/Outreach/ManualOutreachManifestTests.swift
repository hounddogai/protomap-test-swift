@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachManifestTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newManualOutreachManifest("code-839", name: "name-752")
        #expect(item.status == CareManagement.ManualOutreachManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newManualOutreachManifest("code-839", name: "name-752")
        try item.moveTo(CareManagement.ManualOutreachManifestStatus.warming)
        #expect(item.status == CareManagement.ManualOutreachManifestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newManualOutreachManifest("code-839", name: "name-752")
        item.status = CareManagement.ManualOutreachManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachManifestStatus.idle) }
    }
}
