@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingRecallRollup("code-812", title: "title-840")
        let view = Pharmacy.toPendingRecallRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingRecallRollupViews([item, item]).count == 2)
    }
}
