@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRequestTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newWorklistRequest("code-555", label: "label-687")
        #expect(item.status == Imaging.WorklistRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newWorklistRequest("code-555", label: "label-687")
        try item.moveTo(Imaging.WorklistRequestStatus.completed)
        #expect(item.status == Imaging.WorklistRequestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newWorklistRequest("code-555", label: "label-687")
        item.status = Imaging.WorklistRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistRequestStatus.planned) }
    }
}
