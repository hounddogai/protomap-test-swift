@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseVariance("code-861", name: "name-358")
        let view = Pharmacy.toDispenseVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseVarianceViews([item, item]).count == 2)
    }
}
