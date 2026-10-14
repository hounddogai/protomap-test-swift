@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRuleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newReadRule("code-388", name: "name-817")
        #expect(item.status == Imaging.ReadRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newReadRule("code-388", name: "name-817")
        try item.moveTo(Imaging.ReadRuleStatus.queued)
        #expect(item.status == Imaging.ReadRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newReadRule("code-388", name: "name-817")
        item.status = Imaging.ReadRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadRuleStatus.new) }
    }
}
