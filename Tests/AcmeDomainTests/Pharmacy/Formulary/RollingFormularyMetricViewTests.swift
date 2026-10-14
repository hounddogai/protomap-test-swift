@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularyMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingFormularyMetric("code-180", title: "title-582")
        let view = Pharmacy.toRollingFormularyMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingFormularyMetricViews([item, item]).count == 2)
    }
}
