@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadAgreementTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPrimaryReadAgreement("code-762", name: "name-633")
        #expect(item.status == Imaging.PrimaryReadAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newPrimaryReadAgreement("code-762", name: "name-633")
        try item.moveTo(Imaging.PrimaryReadAgreementStatus.validated)
        #expect(item.status == Imaging.PrimaryReadAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPrimaryReadAgreement("code-762", name: "name-633")
        item.status = Imaging.PrimaryReadAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryReadAgreementStatus.created) }
    }
}
