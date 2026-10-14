@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalRecallRequest("code-460", title: "title-110")
        let view = Pharmacy.toRegionalRecallRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalRecallRequestViews([item, item]).count == 2)
    }
}
