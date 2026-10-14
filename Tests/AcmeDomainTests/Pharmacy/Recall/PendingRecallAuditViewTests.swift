@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingRecallAudit("code-921", title: "title-650")
        let view = Pharmacy.toPendingRecallAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingRecallAuditViews([item, item]).count == 2)
    }
}
