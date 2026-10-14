@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRequestTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newCareProtocolRequest("code-232", label: "label-155")
        #expect(item.status == Imaging.CareProtocolRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newCareProtocolRequest("code-232", label: "label-155")
        try item.moveTo(Imaging.CareProtocolRequestStatus.inReview)
        #expect(item.status == Imaging.CareProtocolRequestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newCareProtocolRequest("code-232", label: "label-155")
        item.status = Imaging.CareProtocolRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolRequestStatus.`open`) }
    }
}
