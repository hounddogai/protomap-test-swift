@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityLedgerTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityLedger("code-654", name: "name-472")
        #expect(item.status == Imaging.ModalityLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newModalityLedger("code-654", name: "name-472")
        try item.moveTo(Imaging.ModalityLedgerStatus.published)
        #expect(item.status == Imaging.ModalityLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityLedger("code-654", name: "name-472")
        item.status = Imaging.ModalityLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityLedgerStatus.created) }
    }
}
