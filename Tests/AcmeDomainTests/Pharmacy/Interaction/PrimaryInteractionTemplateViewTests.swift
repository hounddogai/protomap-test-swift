@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        let view = Pharmacy.toPrimaryInteractionTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryInteractionTemplateViews([item, item]).count == 2)
    }
}
