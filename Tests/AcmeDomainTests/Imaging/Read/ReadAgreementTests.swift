@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAgreementTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newReadAgreement("code-545", title: "title-983")
        #expect(item.status == Imaging.ReadAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newReadAgreement("code-545", title: "title-983")
        try item.moveTo(Imaging.ReadAgreementStatus.resolved)
        #expect(item.status == Imaging.ReadAgreementStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newReadAgreement("code-545", title: "title-983")
        item.status = Imaging.ReadAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadAgreementStatus.`open`) }
    }
}
