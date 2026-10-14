@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryFormularyBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryFormularyBatch("code-83", title: "title-839")
        let view = Pharmacy.toPrimaryFormularyBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryFormularyBatchViews([item, item]).count == 2)
    }
}
