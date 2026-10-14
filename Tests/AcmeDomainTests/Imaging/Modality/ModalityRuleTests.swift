@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRuleTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newModalityRule("code-91", title: "title-906")
        #expect(item.status == Imaging.ModalityRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newModalityRule("code-91", title: "title-906")
        try item.moveTo(Imaging.ModalityRuleStatus.revoked)
        #expect(item.status == Imaging.ModalityRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newModalityRule("code-91", title: "title-906")
        item.status = Imaging.ModalityRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityRuleStatus.requested) }
    }
}
