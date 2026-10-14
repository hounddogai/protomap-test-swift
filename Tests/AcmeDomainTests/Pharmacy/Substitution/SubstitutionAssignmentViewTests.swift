@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSubstitutionAssignment("code-783", title: "title-496")
        let view = Pharmacy.toSubstitutionAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSubstitutionAssignmentViews([item, item]).count == 2)
    }
}
