@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryInventoryPlan("code-835", title: "title-659")
        let view = Pharmacy.toPrimaryInventoryPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryInventoryPlanViews([item, item]).count == 2)
    }
}
