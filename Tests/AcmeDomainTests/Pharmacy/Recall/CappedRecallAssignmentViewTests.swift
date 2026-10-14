@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedRecallAssignment("code-268", title: "title-356")
        let view = Pharmacy.toCappedRecallAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedRecallAssignmentViews([item, item]).count == 2)
    }
}
