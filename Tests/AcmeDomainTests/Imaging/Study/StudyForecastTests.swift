@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyForecastTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyForecast("code-287", label: "label-791")
        #expect(item.status == Imaging.StudyForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStudyForecast("code-287", label: "label-791")
        try item.moveTo(Imaging.StudyForecastStatus.approved)
        #expect(item.status == Imaging.StudyForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyForecast("code-287", label: "label-791")
        item.status = Imaging.StudyForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyForecastStatus.proposed) }
    }
}
