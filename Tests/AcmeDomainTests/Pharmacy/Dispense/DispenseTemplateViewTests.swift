@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseTemplate("code-88", name: "name-718")
        let view = Pharmacy.toDispenseTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseTemplateViews([item, item]).count == 2)
    }
}
