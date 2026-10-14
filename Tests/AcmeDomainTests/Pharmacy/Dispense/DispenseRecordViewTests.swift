@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseRecord("code-8", name: "name-207")
        let view = Pharmacy.toDispenseRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseRecordViews([item, item]).count == 2)
    }
}
