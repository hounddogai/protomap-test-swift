@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyPriorityPolicyTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newLegacyPriorityPolicy("code-928", title: "title-695")
        #expect(item.status == Imaging.LegacyPriorityPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newLegacyPriorityPolicy("code-928", title: "title-695")
        try item.moveTo(Imaging.LegacyPriorityPolicyStatus.inReview)
        #expect(item.status == Imaging.LegacyPriorityPolicyStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newLegacyPriorityPolicy("code-928", title: "title-695")
        item.status = Imaging.LegacyPriorityPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyPriorityPolicyStatus.`open`) }
    }
}
