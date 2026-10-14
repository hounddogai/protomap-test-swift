@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistSnapshotTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPrimaryWorklistSnapshot("code-209", title: "title-985")
        #expect(item.status == Imaging.PrimaryWorklistSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newPrimaryWorklistSnapshot("code-209", title: "title-985")
        try item.moveTo(Imaging.PrimaryWorklistSnapshotStatus.revoked)
        #expect(item.status == Imaging.PrimaryWorklistSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPrimaryWorklistSnapshot("code-209", title: "title-985")
        item.status = Imaging.PrimaryWorklistSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryWorklistSnapshotStatus.requested) }
    }
}
