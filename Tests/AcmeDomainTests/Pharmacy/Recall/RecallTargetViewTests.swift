@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallTarget("code-785", name: "name-235")
        let view = Pharmacy.toRecallTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallTargetViews([item, item]).count == 2)
    }
}
