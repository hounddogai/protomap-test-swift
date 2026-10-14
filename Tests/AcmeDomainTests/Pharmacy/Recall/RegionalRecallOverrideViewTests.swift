@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalRecallOverride("code-610", label: "label-393")
        let view = Pharmacy.toRegionalRecallOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalRecallOverrideViews([item, item]).count == 2)
    }
}
