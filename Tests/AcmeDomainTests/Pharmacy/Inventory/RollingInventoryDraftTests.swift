@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryDraftTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRollingInventoryDraft("code-298", label: "label-582")
        #expect(item.status == Pharmacy.RollingInventoryDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newRollingInventoryDraft("code-298", label: "label-582")
        try item.moveTo(Pharmacy.RollingInventoryDraftStatus.inProgress)
        #expect(item.status == Pharmacy.RollingInventoryDraftStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRollingInventoryDraft("code-298", label: "label-582")
        item.status = Pharmacy.RollingInventoryDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingInventoryDraftStatus.planned) }
    }
}
