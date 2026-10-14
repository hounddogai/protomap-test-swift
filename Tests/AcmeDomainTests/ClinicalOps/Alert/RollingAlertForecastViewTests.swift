@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingAlertForecast("code-217", label: "label-55")
        let view = ClinicalOps.toRollingAlertForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingAlertForecastViews([item, item]).count == 2)
    }
}
