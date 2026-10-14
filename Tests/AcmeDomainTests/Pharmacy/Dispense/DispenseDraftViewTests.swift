@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseDraft("code-971", label: "label-720")
        let view = Pharmacy.toDispenseDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseDraftViews([item, item]).count == 2)
    }
}
