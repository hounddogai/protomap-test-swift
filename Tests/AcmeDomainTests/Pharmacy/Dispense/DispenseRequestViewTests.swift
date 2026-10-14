@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        let view = Pharmacy.toDispenseRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseRequestViews([item, item]).count == 2)
    }
}
