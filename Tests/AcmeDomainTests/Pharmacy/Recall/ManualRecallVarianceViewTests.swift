@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualRecallVariance("code-424", name: "name-760")
        let view = Pharmacy.toManualRecallVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualRecallVarianceViews([item, item]).count == 2)
    }
}
