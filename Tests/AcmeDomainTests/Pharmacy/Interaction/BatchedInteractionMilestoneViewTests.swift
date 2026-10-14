@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedInteractionMilestone("code-965", name: "name-516")
        let view = Pharmacy.toBatchedInteractionMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedInteractionMilestoneViews([item, item]).count == 2)
    }
}
