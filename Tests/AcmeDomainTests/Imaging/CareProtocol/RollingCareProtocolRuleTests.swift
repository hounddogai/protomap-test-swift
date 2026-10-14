@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolRuleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRollingCareProtocolRule("code-301", title: "title-496")
        #expect(item.status == Imaging.RollingCareProtocolRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newRollingCareProtocolRule("code-301", title: "title-496")
        try item.moveTo(Imaging.RollingCareProtocolRuleStatus.validated)
        #expect(item.status == Imaging.RollingCareProtocolRuleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRollingCareProtocolRule("code-301", title: "title-496")
        item.status = Imaging.RollingCareProtocolRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolRuleStatus.created) }
    }
}
