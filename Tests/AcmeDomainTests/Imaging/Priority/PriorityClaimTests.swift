@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityClaimTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityClaim("code-592", title: "title-151")
        #expect(item.status == Imaging.PriorityClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newPriorityClaim("code-592", title: "title-151")
        try item.moveTo(Imaging.PriorityClaimStatus.rejected)
        #expect(item.status == Imaging.PriorityClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityClaim("code-592", title: "title-151")
        item.status = Imaging.PriorityClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityClaimStatus.proposed) }
    }
}
