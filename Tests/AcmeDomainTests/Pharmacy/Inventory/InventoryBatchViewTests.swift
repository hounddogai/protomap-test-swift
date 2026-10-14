@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryBatch("code-657", title: "title-266")
        let view = Pharmacy.toInventoryBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryBatchViews([item, item]).count == 2)
    }
}
