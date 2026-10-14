@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierManifestTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        #expect(item.status == Labs.CourierManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        try item.moveTo(Labs.CourierManifestStatus.warming)
        #expect(item.status == Labs.CourierManifestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierManifest("code-254", title: "title-272")
        item.status = Labs.CourierManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierManifestStatus.idle) }
    }
}
