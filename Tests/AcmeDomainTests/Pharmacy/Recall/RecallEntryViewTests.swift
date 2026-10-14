@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallEntry("code-59", name: "name-889")
        let view = Pharmacy.toRecallEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallEntryViews([item, item]).count == 2)
    }
}
