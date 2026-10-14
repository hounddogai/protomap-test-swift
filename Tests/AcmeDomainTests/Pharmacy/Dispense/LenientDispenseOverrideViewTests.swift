@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientDispenseOverride("code-985", title: "title-395")
        let view = Pharmacy.toLenientDispenseOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientDispenseOverrideViews([item, item]).count == 2)
    }
}
