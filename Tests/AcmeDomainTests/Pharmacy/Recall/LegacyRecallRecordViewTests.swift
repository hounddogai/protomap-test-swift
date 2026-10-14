@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        let view = Pharmacy.toLegacyRecallRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyRecallRecordViews([item, item]).count == 2)
    }
}
