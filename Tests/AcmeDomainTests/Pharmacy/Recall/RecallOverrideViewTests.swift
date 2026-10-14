@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallOverride("code-650", name: "name-847")
        let view = Pharmacy.toRecallOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallOverrideViews([item, item]).count == 2)
    }
}
