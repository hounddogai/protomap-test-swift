@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionTemplate("code-565", label: "label-20")
        let view = Pharmacy.toInteractionTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionTemplateViews([item, item]).count == 2)
    }
}
