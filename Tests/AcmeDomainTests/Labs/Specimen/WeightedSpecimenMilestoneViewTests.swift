@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        let view = Labs.toWeightedSpecimenMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedSpecimenMilestoneViews([item, item]).count == 2)
    }
}
