@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyRecallPlan("code-839", name: "name-86")
        let view = Pharmacy.toLegacyRecallPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyRecallPlanViews([item, item]).count == 2)
    }
}
