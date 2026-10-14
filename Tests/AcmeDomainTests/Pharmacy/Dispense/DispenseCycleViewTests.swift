@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        let view = Pharmacy.toDispenseCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseCycleViews([item, item]).count == 2)
    }
}
