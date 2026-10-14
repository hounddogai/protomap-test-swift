@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalModalityClaimTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newRegionalModalityClaim("code-647", label: "label-847")
        #expect(item.status == Imaging.RegionalModalityClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newRegionalModalityClaim("code-647", label: "label-847")
        try item.moveTo(Imaging.RegionalModalityClaimStatus.approved)
        #expect(item.status == Imaging.RegionalModalityClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newRegionalModalityClaim("code-647", label: "label-847")
        item.status = Imaging.RegionalModalityClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalModalityClaimStatus.proposed) }
    }
}
