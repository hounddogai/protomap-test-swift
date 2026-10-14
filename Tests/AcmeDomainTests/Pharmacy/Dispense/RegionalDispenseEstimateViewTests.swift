@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalDispenseEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalDispenseEstimate("code-409", name: "name-588")
        let view = Pharmacy.toRegionalDispenseEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalDispenseEstimateViews([item, item]).count == 2)
    }
}
