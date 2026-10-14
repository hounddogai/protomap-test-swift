@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualWorklistAgreementTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newManualWorklistAgreement("code-749", title: "title-665")
        #expect(item.status == Imaging.ManualWorklistAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newManualWorklistAgreement("code-749", title: "title-665")
        try item.moveTo(Imaging.ManualWorklistAgreementStatus.approved)
        #expect(item.status == Imaging.ManualWorklistAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newManualWorklistAgreement("code-749", title: "title-665")
        item.status = Imaging.ManualWorklistAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualWorklistAgreementStatus.proposed) }
    }
}
