@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedDispenseBundle("code-133", label: "label-786")
        let view = Pharmacy.toBatchedDispenseBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedDispenseBundleViews([item, item]).count == 2)
    }
}
