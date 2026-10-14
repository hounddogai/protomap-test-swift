@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyEstimate("code-376", title: "title-731")
        let view = Pharmacy.toFormularyEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyEstimateViews([item, item]).count == 2)
    }
}
