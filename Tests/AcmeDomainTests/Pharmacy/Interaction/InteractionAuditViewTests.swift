@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionAudit("code-757", name: "name-897")
        let view = Pharmacy.toInteractionAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionAuditViews([item, item]).count == 2)
    }
}
