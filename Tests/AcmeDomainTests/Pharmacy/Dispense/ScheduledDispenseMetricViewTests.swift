@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledDispenseMetric("code-60", name: "name-48")
        let view = Pharmacy.toScheduledDispenseMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledDispenseMetricViews([item, item]).count == 2)
    }
}
