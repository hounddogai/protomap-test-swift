@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapManifestTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newCareGapManifest("code-201", title: "title-287")
        #expect(item.status == CareManagement.CareGapManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newCareGapManifest("code-201", title: "title-287")
        try item.moveTo(CareManagement.CareGapManifestStatus.ready)
        #expect(item.status == CareManagement.CareGapManifestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newCareGapManifest("code-201", title: "title-287")
        item.status = CareManagement.CareGapManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapManifestStatus.idle) }
    }
}
