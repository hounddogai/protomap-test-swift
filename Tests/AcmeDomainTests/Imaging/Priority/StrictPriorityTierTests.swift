@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityTierTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        #expect(item.status == Imaging.StrictPriorityTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        try item.moveTo(Imaging.StrictPriorityTierStatus.archived)
        #expect(item.status == Imaging.StrictPriorityTierStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        item.status = Imaging.StrictPriorityTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictPriorityTierStatus.`open`) }
    }
}
