@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledFormularyMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledFormularyMilestone("code-529", title: "title-754")
        let view = Pharmacy.toScheduledFormularyMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledFormularyMilestoneViews([item, item]).count == 2)
    }
}
