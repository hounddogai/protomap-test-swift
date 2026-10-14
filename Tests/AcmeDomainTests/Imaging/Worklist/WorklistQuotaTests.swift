@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistQuotaTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistQuota("code-730", title: "title-495")
        #expect(item.status == Imaging.WorklistQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newWorklistQuota("code-730", title: "title-495")
        try item.moveTo(Imaging.WorklistQuotaStatus.approved)
        #expect(item.status == Imaging.WorklistQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistQuota("code-730", title: "title-495")
        item.status = Imaging.WorklistQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistQuotaStatus.proposed) }
    }
}
