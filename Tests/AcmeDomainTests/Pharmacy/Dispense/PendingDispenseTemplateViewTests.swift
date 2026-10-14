@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingDispenseTemplate("code-541", title: "title-662")
        let view = Pharmacy.toPendingDispenseTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingDispenseTemplateViews([item, item]).count == 2)
    }
}
