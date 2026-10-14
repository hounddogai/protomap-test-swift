@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolLedgerTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolLedger("code-697", label: "label-758")
        #expect(item.status == Imaging.CareProtocolLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newCareProtocolLedger("code-697", label: "label-758")
        try item.moveTo(Imaging.CareProtocolLedgerStatus.failed)
        #expect(item.status == Imaging.CareProtocolLedgerStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolLedger("code-697", label: "label-758")
        item.status = Imaging.CareProtocolLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolLedgerStatus.new) }
    }
}
