@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingRecallTemplate("code-13", title: "title-253")
        let view = Pharmacy.toPendingRecallTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingRecallTemplateViews([item, item]).count == 2)
    }
}
