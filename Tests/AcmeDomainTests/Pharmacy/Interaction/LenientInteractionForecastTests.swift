@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionForecastTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newLenientInteractionForecast("code-680", label: "label-553")
        #expect(item.status == Pharmacy.LenientInteractionForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newLenientInteractionForecast("code-680", label: "label-553")
        try item.moveTo(Pharmacy.LenientInteractionForecastStatus.published)
        #expect(item.status == Pharmacy.LenientInteractionForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newLenientInteractionForecast("code-680", label: "label-553")
        item.status = Pharmacy.LenientInteractionForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInteractionForecastStatus.created) }
    }
}
