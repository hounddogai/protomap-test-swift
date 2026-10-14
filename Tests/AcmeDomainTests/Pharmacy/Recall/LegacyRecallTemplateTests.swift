@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLegacyRecallTemplate("code-696", title: "title-385")
        #expect(item.status == Pharmacy.LegacyRecallTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newLegacyRecallTemplate("code-696", title: "title-385")
        try item.moveTo(Pharmacy.LegacyRecallTemplateStatus.scheduled)
        #expect(item.status == Pharmacy.LegacyRecallTemplateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLegacyRecallTemplate("code-696", title: "title-385")
        item.status = Pharmacy.LegacyRecallTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyRecallTemplateStatus.planned) }
    }
}
