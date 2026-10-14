@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAgreementTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newDefaultPriorityAgreement("code-558", label: "label-245")
        #expect(item.status == Imaging.DefaultPriorityAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newDefaultPriorityAgreement("code-558", label: "label-245")
        try item.moveTo(Imaging.DefaultPriorityAgreementStatus.rejected)
        #expect(item.status == Imaging.DefaultPriorityAgreementStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newDefaultPriorityAgreement("code-558", label: "label-245")
        item.status = Imaging.DefaultPriorityAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultPriorityAgreementStatus.proposed) }
    }
}
