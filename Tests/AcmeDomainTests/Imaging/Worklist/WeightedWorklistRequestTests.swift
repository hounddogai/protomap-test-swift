@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistRequestTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWeightedWorklistRequest("code-720", title: "title-386")
        #expect(item.status == Imaging.WeightedWorklistRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWeightedWorklistRequest("code-720", title: "title-386")
        try item.moveTo(Imaging.WeightedWorklistRequestStatus.validated)
        #expect(item.status == Imaging.WeightedWorklistRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWeightedWorklistRequest("code-720", title: "title-386")
        item.status = Imaging.WeightedWorklistRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedWorklistRequestStatus.created) }
    }
}
