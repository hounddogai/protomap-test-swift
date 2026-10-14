@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInventoryScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newTieredInventoryScore("code-415", title: "title-729")
        let view = Pharmacy.toTieredInventoryScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toTieredInventoryScoreViews([item, item]).count == 2)
    }
}
