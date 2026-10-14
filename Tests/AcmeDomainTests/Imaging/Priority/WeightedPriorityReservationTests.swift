@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedPriorityReservationTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWeightedPriorityReservation("code-309", label: "label-895")
        #expect(item.status == Imaging.WeightedPriorityReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newWeightedPriorityReservation("code-309", label: "label-895")
        try item.moveTo(Imaging.WeightedPriorityReservationStatus.inReview)
        #expect(item.status == Imaging.WeightedPriorityReservationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWeightedPriorityReservation("code-309", label: "label-895")
        item.status = Imaging.WeightedPriorityReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedPriorityReservationStatus.`open`) }
    }
}
