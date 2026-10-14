@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyCycle("code-252", title: "title-94")
        let view = Pharmacy.toFormularyCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyCycleViews([item, item]).count == 2)
    }
}
