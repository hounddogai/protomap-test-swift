@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newSeasonalWorklistAssignment("code-414", label: "label-850")
        #expect(item.status == Imaging.SeasonalWorklistAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newSeasonalWorklistAssignment("code-414", label: "label-850")
        try item.moveTo(Imaging.SeasonalWorklistAssignmentStatus.validated)
        #expect(item.status == Imaging.SeasonalWorklistAssignmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newSeasonalWorklistAssignment("code-414", label: "label-850")
        item.status = Imaging.SeasonalWorklistAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalWorklistAssignmentStatus.created) }
    }
}
