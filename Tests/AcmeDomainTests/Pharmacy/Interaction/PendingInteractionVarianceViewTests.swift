@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingInteractionVariance("code-422", label: "label-964")
        let view = Pharmacy.toPendingInteractionVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingInteractionVarianceViews([item, item]).count == 2)
    }
}
