@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallDraft("code-68", title: "title-626")
        let view = Pharmacy.toRecallDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallDraftViews([item, item]).count == 2)
    }
}
