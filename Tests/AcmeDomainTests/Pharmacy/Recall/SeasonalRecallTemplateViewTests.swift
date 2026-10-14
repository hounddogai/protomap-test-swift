@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalRecallTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSeasonalRecallTemplate("code-195", title: "title-295")
        let view = Pharmacy.toSeasonalRecallTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSeasonalRecallTemplateViews([item, item]).count == 2)
    }
}
