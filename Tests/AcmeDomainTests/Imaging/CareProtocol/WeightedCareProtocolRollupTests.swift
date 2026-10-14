@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolRollupTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWeightedCareProtocolRollup("code-735", label: "label-753")
        #expect(item.status == Imaging.WeightedCareProtocolRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newWeightedCareProtocolRollup("code-735", label: "label-753")
        try item.moveTo(Imaging.WeightedCareProtocolRollupStatus.reopened)
        #expect(item.status == Imaging.WeightedCareProtocolRollupStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWeightedCareProtocolRollup("code-735", label: "label-753")
        item.status = Imaging.WeightedCareProtocolRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedCareProtocolRollupStatus.`open`) }
    }
}
