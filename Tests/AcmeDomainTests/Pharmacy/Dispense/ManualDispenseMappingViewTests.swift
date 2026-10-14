@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualDispenseMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualDispenseMapping("code-701", label: "label-317")
        let view = Pharmacy.toManualDispenseMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualDispenseMappingViews([item, item]).count == 2)
    }
}
