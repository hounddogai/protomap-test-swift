@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseNotice("code-691", title: "title-852")
        let view = Pharmacy.toDispenseNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseNoticeViews([item, item]).count == 2)
    }
}
