@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictFormularyDraft("code-636", title: "title-370")
        let view = Pharmacy.toStrictFormularyDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictFormularyDraftViews([item, item]).count == 2)
    }
}
