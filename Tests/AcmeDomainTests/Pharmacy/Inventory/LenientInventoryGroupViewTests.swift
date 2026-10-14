@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInventoryGroup("code-625", title: "title-194")
        let view = Pharmacy.toLenientInventoryGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInventoryGroupViews([item, item]).count == 2)
    }
}
