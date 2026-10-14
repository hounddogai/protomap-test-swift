@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventorySegment("code-238", name: "name-696")
        let view = Pharmacy.toInventorySegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventorySegmentViews([item, item]).count == 2)
    }
}
