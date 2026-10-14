@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseEstimate("code-321", title: "title-748")
        let view = Pharmacy.toDispenseEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseEstimateViews([item, item]).count == 2)
    }
}
