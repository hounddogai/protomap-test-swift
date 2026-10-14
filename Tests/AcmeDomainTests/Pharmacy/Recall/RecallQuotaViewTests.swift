@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallQuota("code-195", title: "title-54")
        let view = Pharmacy.toRecallQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallQuotaViews([item, item]).count == 2)
    }
}
