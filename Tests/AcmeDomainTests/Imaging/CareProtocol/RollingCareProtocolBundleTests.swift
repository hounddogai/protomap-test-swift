@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolBundleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRollingCareProtocolBundle("code-696", title: "title-235")
        #expect(item.status == Imaging.RollingCareProtocolBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newRollingCareProtocolBundle("code-696", title: "title-235")
        try item.moveTo(Imaging.RollingCareProtocolBundleStatus.validated)
        #expect(item.status == Imaging.RollingCareProtocolBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRollingCareProtocolBundle("code-696", title: "title-235")
        item.status = Imaging.RollingCareProtocolBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolBundleStatus.created) }
    }
}
