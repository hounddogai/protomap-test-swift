@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolOverrideTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRollingCareProtocolOverride("code-950", title: "title-505")
        #expect(item.status == Imaging.RollingCareProtocolOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newRollingCareProtocolOverride("code-950", title: "title-505")
        try item.moveTo(Imaging.RollingCareProtocolOverrideStatus.validated)
        #expect(item.status == Imaging.RollingCareProtocolOverrideStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRollingCareProtocolOverride("code-950", title: "title-505")
        item.status = Imaging.RollingCareProtocolOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolOverrideStatus.created) }
    }
}
