@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSubstitutionRecord("code-676", name: "name-856")
        let view = Pharmacy.toSubstitutionRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSubstitutionRecordViews([item, item]).count == 2)
    }
}
