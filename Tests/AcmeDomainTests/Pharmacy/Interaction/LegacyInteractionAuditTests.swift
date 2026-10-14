@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionAuditTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newLegacyInteractionAudit("code-5", name: "name-59")
        #expect(item.status == Pharmacy.LegacyInteractionAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newLegacyInteractionAudit("code-5", name: "name-59")
        try item.moveTo(Pharmacy.LegacyInteractionAuditStatus.active)
        #expect(item.status == Pharmacy.LegacyInteractionAuditStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newLegacyInteractionAudit("code-5", name: "name-59")
        item.status = Pharmacy.LegacyInteractionAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionAuditStatus.draft) }
    }
}
