@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryEstimate("code-877", name: "name-669")
        let view = Pharmacy.toInventoryEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryEstimateViews([item, item]).count == 2)
    }
}
