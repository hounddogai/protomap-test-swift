@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingRecallTier("code-382", name: "name-620")
        let view = Pharmacy.toRollingRecallTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingRecallTierViews([item, item]).count == 2)
    }
}
