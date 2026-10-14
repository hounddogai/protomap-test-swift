@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistManifestTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newWorklistManifest("code-612", title: "title-730")
        #expect(item.status == Imaging.WorklistManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newWorklistManifest("code-612", title: "title-730")
        try item.moveTo(Imaging.WorklistManifestStatus.ready)
        #expect(item.status == Imaging.WorklistManifestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newWorklistManifest("code-612", title: "title-730")
        item.status = Imaging.WorklistManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistManifestStatus.idle) }
    }
}
