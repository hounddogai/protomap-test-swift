@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallWindow("code-442", title: "title-750")
        let view = Pharmacy.toRecallWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallWindowViews([item, item]).count == 2)
    }
}
