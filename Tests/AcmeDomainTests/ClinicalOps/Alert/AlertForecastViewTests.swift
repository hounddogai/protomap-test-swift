@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertForecast("code-584", title: "title-622")
        let view = ClinicalOps.toAlertForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertForecastViews([item, item]).count == 2)
    }
}
