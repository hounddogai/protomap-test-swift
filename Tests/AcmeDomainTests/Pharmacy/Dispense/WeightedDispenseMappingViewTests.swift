@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedDispenseMapping("code-167", label: "label-924")
        let view = Pharmacy.toWeightedDispenseMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedDispenseMappingViews([item, item]).count == 2)
    }
}
