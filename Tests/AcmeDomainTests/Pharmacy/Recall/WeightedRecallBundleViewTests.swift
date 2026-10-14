@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedRecallBundle("code-319", title: "title-961")
        let view = Pharmacy.toWeightedRecallBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedRecallBundleViews([item, item]).count == 2)
    }
}
