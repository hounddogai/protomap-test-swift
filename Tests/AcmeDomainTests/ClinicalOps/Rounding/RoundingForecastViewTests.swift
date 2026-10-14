@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRoundingForecast("code-621", label: "label-421")
        let view = ClinicalOps.toRoundingForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRoundingForecastViews([item, item]).count == 2)
    }
}
