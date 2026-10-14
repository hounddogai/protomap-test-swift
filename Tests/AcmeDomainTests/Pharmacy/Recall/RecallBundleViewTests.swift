@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallBundle("code-591", label: "label-709")
        let view = Pharmacy.toRecallBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallBundleViews([item, item]).count == 2)
    }
}
