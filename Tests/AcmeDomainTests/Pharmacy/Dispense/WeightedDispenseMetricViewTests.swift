@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedDispenseMetric("code-854", name: "name-703")
        let view = Pharmacy.toWeightedDispenseMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedDispenseMetricViews([item, item]).count == 2)
    }
}
