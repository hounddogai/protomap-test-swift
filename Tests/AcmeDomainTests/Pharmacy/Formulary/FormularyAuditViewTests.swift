@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyAudit("code-490", label: "label-729")
        let view = Pharmacy.toFormularyAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyAuditViews([item, item]).count == 2)
    }
}
