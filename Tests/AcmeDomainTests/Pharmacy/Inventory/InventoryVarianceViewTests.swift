@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryVariance("code-822", title: "title-829")
        let view = Pharmacy.toInventoryVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryVarianceViews([item, item]).count == 2)
    }
}
