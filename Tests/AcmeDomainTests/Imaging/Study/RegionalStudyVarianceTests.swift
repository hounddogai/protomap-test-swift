@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyVarianceTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newRegionalStudyVariance("code-54", title: "title-65")
        #expect(item.status == Imaging.RegionalStudyVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newRegionalStudyVariance("code-54", title: "title-65")
        try item.moveTo(Imaging.RegionalStudyVarianceStatus.inReview)
        #expect(item.status == Imaging.RegionalStudyVarianceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newRegionalStudyVariance("code-54", title: "title-65")
        item.status = Imaging.RegionalStudyVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyVarianceStatus.`open`) }
    }
}
