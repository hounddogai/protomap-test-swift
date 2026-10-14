@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedRecallCycle("code-7", name: "name-518")
        let view = Pharmacy.toWeightedRecallCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedRecallCycleViews([item, item]).count == 2)
    }
}
