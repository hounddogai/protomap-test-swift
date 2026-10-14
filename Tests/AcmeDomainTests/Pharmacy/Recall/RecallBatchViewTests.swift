@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallBatch("code-244", label: "label-172")
        let view = Pharmacy.toRecallBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallBatchViews([item, item]).count == 2)
    }
}
