@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedFormularyEstimate("code-985", label: "label-113")
        let view = Pharmacy.toWeightedFormularyEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedFormularyEstimateViews([item, item]).count == 2)
    }
}
