@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySummaryTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        #expect(item.status == Imaging.StudySummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        try item.moveTo(Imaging.StudySummaryStatus.published)
        #expect(item.status == Imaging.StudySummaryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        item.status = Imaging.StudySummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudySummaryStatus.created) }
    }
}
