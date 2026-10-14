@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTemplateTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newReadTemplate("code-167", label: "label-839")
        #expect(item.status == Imaging.ReadTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newReadTemplate("code-167", label: "label-839")
        try item.moveTo(Imaging.ReadTemplateStatus.revoked)
        #expect(item.status == Imaging.ReadTemplateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newReadTemplate("code-167", label: "label-839")
        item.status = Imaging.ReadTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadTemplateStatus.requested) }
    }
}
