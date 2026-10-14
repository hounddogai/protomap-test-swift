@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedDispenseAssignment("code-688", label: "label-30")
        let view = Pharmacy.toWeightedDispenseAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedDispenseAssignmentViews([item, item]).count == 2)
    }
}
