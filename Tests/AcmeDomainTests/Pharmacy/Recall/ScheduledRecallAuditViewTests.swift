@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledRecallAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledRecallAudit("code-839", label: "label-626")
        let view = Pharmacy.toScheduledRecallAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledRecallAuditViews([item, item]).count == 2)
    }
}
