@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualRecallNotice("code-391", label: "label-700")
        let view = Pharmacy.toManualRecallNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualRecallNoticeViews([item, item]).count == 2)
    }
}
