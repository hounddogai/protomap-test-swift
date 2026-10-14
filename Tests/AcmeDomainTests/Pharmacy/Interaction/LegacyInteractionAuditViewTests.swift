@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyInteractionAudit("code-5", name: "name-59")
        let view = Pharmacy.toLegacyInteractionAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyInteractionAuditViews([item, item]).count == 2)
    }
}
