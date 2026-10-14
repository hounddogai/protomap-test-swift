@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientFormularyDraftTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newLenientFormularyDraft("code-149", name: "name-692")
        #expect(item.status == Pharmacy.LenientFormularyDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newLenientFormularyDraft("code-149", name: "name-692")
        try item.moveTo(Pharmacy.LenientFormularyDraftStatus.running)
        #expect(item.status == Pharmacy.LenientFormularyDraftStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newLenientFormularyDraft("code-149", name: "name-692")
        item.status = Pharmacy.LenientFormularyDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientFormularyDraftStatus.new) }
    }
}
