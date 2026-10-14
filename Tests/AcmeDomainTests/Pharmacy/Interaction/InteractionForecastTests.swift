@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionForecastTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInteractionForecast("code-659", title: "title-893")
        #expect(item.status == Pharmacy.InteractionForecastStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newInteractionForecast("code-659", title: "title-893")
        try item.moveTo(Pharmacy.InteractionForecastStatus.queued)
        #expect(item.status == Pharmacy.InteractionForecastStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInteractionForecast("code-659", title: "title-893")
        item.status = Pharmacy.InteractionForecastStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionForecastStatus.new) }
    }
}
