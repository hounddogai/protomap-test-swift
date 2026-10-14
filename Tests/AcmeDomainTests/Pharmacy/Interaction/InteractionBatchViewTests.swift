@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionBatch("code-615", name: "name-662")
        let view = Pharmacy.toInteractionBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionBatchViews([item, item]).count == 2)
    }
}
