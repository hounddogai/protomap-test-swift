@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseAssignment("code-231", label: "label-283")
        let view = Pharmacy.toDispenseAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseAssignmentViews([item, item]).count == 2)
    }
}
