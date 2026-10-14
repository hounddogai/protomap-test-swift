@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyAssignment("code-611", name: "name-381")
        let view = Pharmacy.toFormularyAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyAssignmentViews([item, item]).count == 2)
    }
}
