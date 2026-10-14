@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictDispenseEstimate("code-962", name: "name-782")
        let view = Pharmacy.toStrictDispenseEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictDispenseEstimateViews([item, item]).count == 2)
    }
}
