@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityTargetTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newRegionalPriorityTarget("code-111", label: "label-8")
        #expect(item.status == Imaging.RegionalPriorityTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newRegionalPriorityTarget("code-111", label: "label-8")
        try item.moveTo(Imaging.RegionalPriorityTargetStatus.withdrawn)
        #expect(item.status == Imaging.RegionalPriorityTargetStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newRegionalPriorityTarget("code-111", label: "label-8")
        item.status = Imaging.RegionalPriorityTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalPriorityTargetStatus.proposed) }
    }
}
