@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackRecallTemplate("code-152", name: "name-944")
        let view = Pharmacy.toFallbackRecallTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackRecallTemplateViews([item, item]).count == 2)
    }
}
