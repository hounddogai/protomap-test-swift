@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityPolicyTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityPolicy("code-64", label: "label-620")
        #expect(item.status == Imaging.PriorityPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newPriorityPolicy("code-64", label: "label-620")
        try item.moveTo(Imaging.PriorityPolicyStatus.approved)
        #expect(item.status == Imaging.PriorityPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityPolicy("code-64", label: "label-620")
        item.status = Imaging.PriorityPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityPolicyStatus.proposed) }
    }
}
