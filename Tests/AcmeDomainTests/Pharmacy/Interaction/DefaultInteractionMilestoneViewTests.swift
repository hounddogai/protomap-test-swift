@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultInteractionMilestone("code-241", label: "label-749")
        let view = Pharmacy.toDefaultInteractionMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultInteractionMilestoneViews([item, item]).count == 2)
    }
}
