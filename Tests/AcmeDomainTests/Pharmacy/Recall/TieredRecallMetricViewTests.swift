@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredRecallMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newTieredRecallMetric("code-926", name: "name-207")
        let view = Pharmacy.toTieredRecallMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toTieredRecallMetricViews([item, item]).count == 2)
    }
}
