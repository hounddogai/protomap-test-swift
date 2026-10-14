@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallMetric("code-389", name: "name-198")
        let view = Pharmacy.toRecallMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallMetricViews([item, item]).count == 2)
    }
}
