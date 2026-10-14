@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallForecastTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallForecast("code-715", title: "title-804")
        #expect(item.status == Pharmacy.RecallForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newRecallForecast("code-715", title: "title-804")
        try item.moveTo(Pharmacy.RecallForecastStatus.expired)
        #expect(item.status == Pharmacy.RecallForecastStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallForecast("code-715", title: "title-804")
        item.status = Pharmacy.RecallForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallForecastStatus.requested) }
    }
}
