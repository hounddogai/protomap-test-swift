@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallForecastTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDefaultRecallForecast("code-766", title: "title-636")
        #expect(item.status == Pharmacy.DefaultRecallForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newDefaultRecallForecast("code-766", title: "title-636")
        try item.moveTo(Pharmacy.DefaultRecallForecastStatus.retired)
        #expect(item.status == Pharmacy.DefaultRecallForecastStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDefaultRecallForecast("code-766", title: "title-636")
        item.status = Pharmacy.DefaultRecallForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultRecallForecastStatus.created) }
    }
}
