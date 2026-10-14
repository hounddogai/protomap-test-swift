@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionRecord("code-950", name: "name-231")
        let view = Pharmacy.toInteractionRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionRecordViews([item, item]).count == 2)
    }
}
