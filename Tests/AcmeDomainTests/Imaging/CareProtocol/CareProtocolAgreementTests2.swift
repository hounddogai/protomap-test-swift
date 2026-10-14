@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAgreementTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newCareProtocolAgreement("code-174", title: "title-404")
        #expect(item.status == Imaging.CareProtocolAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newCareProtocolAgreement("code-174", title: "title-404")
        try item.moveTo(Imaging.CareProtocolAgreementStatus.validated)
        #expect(item.status == Imaging.CareProtocolAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newCareProtocolAgreement("code-174", title: "title-404")
        item.status = Imaging.CareProtocolAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolAgreementStatus.created) }
    }
}
