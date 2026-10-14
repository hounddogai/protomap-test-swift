@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallAudit("code-406", label: "label-625")
        let view = Pharmacy.toRecallAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallAuditViews([item, item]).count == 2)
    }
}
