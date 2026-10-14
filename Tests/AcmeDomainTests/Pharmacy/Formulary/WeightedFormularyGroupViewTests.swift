@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        let view = Pharmacy.toWeightedFormularyGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedFormularyGroupViews([item, item]).count == 2)
    }
}
