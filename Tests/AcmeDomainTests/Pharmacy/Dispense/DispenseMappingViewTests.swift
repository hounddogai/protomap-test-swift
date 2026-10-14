@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseMapping("code-231", name: "name-903")
        let view = Pharmacy.toDispenseMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseMappingViews([item, item]).count == 2)
    }
}
