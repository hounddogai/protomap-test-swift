@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingRecallPlan("code-718", name: "name-65")
        let view = Pharmacy.toRollingRecallPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingRecallPlanViews([item, item]).count == 2)
    }
}
