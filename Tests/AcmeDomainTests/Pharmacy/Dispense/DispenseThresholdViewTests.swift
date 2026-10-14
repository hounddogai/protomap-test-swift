@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseThreshold("code-879", label: "label-30")
        let view = Pharmacy.toDispenseThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseThresholdViews([item, item]).count == 2)
    }
}
