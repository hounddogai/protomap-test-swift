@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingInventoryDraft("code-298", label: "label-582")
        let view = Pharmacy.toRollingInventoryDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingInventoryDraftViews([item, item]).count == 2)
    }
}
