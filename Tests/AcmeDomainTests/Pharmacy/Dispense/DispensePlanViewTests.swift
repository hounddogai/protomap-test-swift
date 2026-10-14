@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispensePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispensePlan("code-465", title: "title-450")
        let view = Pharmacy.toDispensePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispensePlanViews([item, item]).count == 2)
    }
}
