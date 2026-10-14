@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultFormularyOverride("code-196", name: "name-891")
        let view = Pharmacy.toDefaultFormularyOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultFormularyOverrideViews([item, item]).count == 2)
    }
}
