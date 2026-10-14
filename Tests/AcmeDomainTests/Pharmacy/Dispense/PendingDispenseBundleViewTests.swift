@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingDispenseBundle("code-780", name: "name-603")
        let view = Pharmacy.toPendingDispenseBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingDispenseBundleViews([item, item]).count == 2)
    }
}
