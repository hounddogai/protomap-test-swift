@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityRequestTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newCappedModalityRequest("code-119", label: "label-197")
        #expect(item.status == Imaging.CappedModalityRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newCappedModalityRequest("code-119", label: "label-197")
        try item.moveTo(Imaging.CappedModalityRequestStatus.validated)
        #expect(item.status == Imaging.CappedModalityRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newCappedModalityRequest("code-119", label: "label-197")
        item.status = Imaging.CappedModalityRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityRequestStatus.created) }
    }
}
