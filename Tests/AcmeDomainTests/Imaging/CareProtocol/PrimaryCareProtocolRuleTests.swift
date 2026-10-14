@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolRuleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPrimaryCareProtocolRule("code-942", title: "title-734")
        #expect(item.status == Imaging.PrimaryCareProtocolRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newPrimaryCareProtocolRule("code-942", title: "title-734")
        try item.moveTo(Imaging.PrimaryCareProtocolRuleStatus.running)
        #expect(item.status == Imaging.PrimaryCareProtocolRuleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPrimaryCareProtocolRule("code-942", title: "title-734")
        item.status = Imaging.PrimaryCareProtocolRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryCareProtocolRuleStatus.new) }
    }
}
