@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualRecallQuota("code-839", label: "label-907")
        let view = Pharmacy.toManualRecallQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualRecallQuotaViews([item, item]).count == 2)
    }
}
