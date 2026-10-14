@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallNotice("code-967", title: "title-490")
        let view = Pharmacy.toRecallNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallNoticeViews([item, item]).count == 2)
    }
}
