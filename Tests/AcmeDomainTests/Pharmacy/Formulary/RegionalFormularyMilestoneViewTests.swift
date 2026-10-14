@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalFormularyMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalFormularyMilestone("code-526", label: "label-490")
        let view = Pharmacy.toRegionalFormularyMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalFormularyMilestoneViews([item, item]).count == 2)
    }
}
