@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveInventoryNotice("code-584", title: "title-470")
        let view = Pharmacy.toAdaptiveInventoryNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveInventoryNoticeViews([item, item]).count == 2)
    }
}
