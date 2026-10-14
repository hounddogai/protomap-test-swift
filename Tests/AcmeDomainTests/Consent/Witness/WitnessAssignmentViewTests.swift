@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessAssignment("code-870", title: "title-484")
        let view = Consent.toWitnessAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessAssignmentViews([item, item]).count == 2)
    }
}
