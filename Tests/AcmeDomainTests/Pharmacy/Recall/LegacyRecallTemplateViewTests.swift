@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyRecallTemplate("code-696", title: "title-385")
        let view = Pharmacy.toLegacyRecallTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyRecallTemplateViews([item, item]).count == 2)
    }
}
