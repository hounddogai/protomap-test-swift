@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadPreferenceTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWeightedReadPreference("code-253", title: "title-753")
        #expect(item.status == Imaging.WeightedReadPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newWeightedReadPreference("code-253", title: "title-753")
        try item.moveTo(Imaging.WeightedReadPreferenceStatus.inReview)
        #expect(item.status == Imaging.WeightedReadPreferenceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWeightedReadPreference("code-253", title: "title-753")
        item.status = Imaging.WeightedReadPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedReadPreferenceStatus.`open`) }
    }
}
