@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newOrderSetForecast("code-405", label: "label-213")
        let view = ClinicalOps.toOrderSetForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toOrderSetForecastViews([item, item]).count == 2)
    }
}
