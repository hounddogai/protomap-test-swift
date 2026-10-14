@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientFormularyDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientFormularyDraft("code-149", name: "name-692")
        let view = Pharmacy.toLenientFormularyDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientFormularyDraftViews([item, item]).count == 2)
    }
}
