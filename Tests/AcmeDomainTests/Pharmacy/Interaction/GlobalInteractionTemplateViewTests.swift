@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInteractionTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newGlobalInteractionTemplate("code-301", title: "title-880")
        let view = Pharmacy.toGlobalInteractionTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toGlobalInteractionTemplateViews([item, item]).count == 2)
    }
}
