@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseBundle("code-808", title: "title-750")
        let view = Pharmacy.toDispenseBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseBundleViews([item, item]).count == 2)
    }
}
