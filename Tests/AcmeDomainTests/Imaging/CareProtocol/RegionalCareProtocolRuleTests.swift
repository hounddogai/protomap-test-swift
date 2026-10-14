@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalCareProtocolRuleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRegionalCareProtocolRule("code-754", label: "label-306")
        #expect(item.status == Imaging.RegionalCareProtocolRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newRegionalCareProtocolRule("code-754", label: "label-306")
        try item.moveTo(Imaging.RegionalCareProtocolRuleStatus.validated)
        #expect(item.status == Imaging.RegionalCareProtocolRuleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRegionalCareProtocolRule("code-754", label: "label-306")
        item.status = Imaging.RegionalCareProtocolRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalCareProtocolRuleStatus.created) }
    }
}
