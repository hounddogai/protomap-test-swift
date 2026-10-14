@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallThreshold("code-124", name: "name-154")
        let view = Pharmacy.toRecallThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallThresholdViews([item, item]).count == 2)
    }
}
