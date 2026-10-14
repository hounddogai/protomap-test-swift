@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        let view = Pharmacy.toPrimaryRecallPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryRecallPlanViews([item, item]).count == 2)
    }
}
