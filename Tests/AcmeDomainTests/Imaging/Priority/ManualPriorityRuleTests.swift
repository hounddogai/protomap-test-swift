@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityRuleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newManualPriorityRule("code-87", title: "title-76")
        #expect(item.status == Imaging.ManualPriorityRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newManualPriorityRule("code-87", title: "title-76")
        try item.moveTo(Imaging.ManualPriorityRuleStatus.done)
        #expect(item.status == Imaging.ManualPriorityRuleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newManualPriorityRule("code-87", title: "title-76")
        item.status = Imaging.ManualPriorityRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualPriorityRuleStatus.new) }
    }
}
