@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolManifestTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newRollingCareProtocolManifest("code-231", label: "label-723")
        #expect(item.status == Imaging.RollingCareProtocolManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newRollingCareProtocolManifest("code-231", label: "label-723")
        try item.moveTo(Imaging.RollingCareProtocolManifestStatus.revoked)
        #expect(item.status == Imaging.RollingCareProtocolManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newRollingCareProtocolManifest("code-231", label: "label-723")
        item.status = Imaging.RollingCareProtocolManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolManifestStatus.requested) }
    }
}
