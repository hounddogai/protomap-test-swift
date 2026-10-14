@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedDispenseCycle("code-366", title: "title-898")
        let view = Pharmacy.toWeightedDispenseCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedDispenseCycleViews([item, item]).count == 2)
    }
}
