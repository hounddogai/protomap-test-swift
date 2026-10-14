@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalRecallTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newSeasonalRecallTemplate("code-195", title: "title-295")
        #expect(item.status == Pharmacy.SeasonalRecallTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newSeasonalRecallTemplate("code-195", title: "title-295")
        try item.moveTo(Pharmacy.SeasonalRecallTemplateStatus.inProgress)
        #expect(item.status == Pharmacy.SeasonalRecallTemplateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newSeasonalRecallTemplate("code-195", title: "title-295")
        item.status = Pharmacy.SeasonalRecallTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalRecallTemplateStatus.planned) }
    }
}
