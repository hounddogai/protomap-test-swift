@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInteractionDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        let view = Pharmacy.toTieredInteractionDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toTieredInteractionDraftViews([item, item]).count == 2)
    }
}
