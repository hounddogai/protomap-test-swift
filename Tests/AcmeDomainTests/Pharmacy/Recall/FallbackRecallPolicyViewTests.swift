@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackRecallPolicy("code-66", label: "label-429")
        let view = Pharmacy.toFallbackRecallPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackRecallPolicyViews([item, item]).count == 2)
    }
}
