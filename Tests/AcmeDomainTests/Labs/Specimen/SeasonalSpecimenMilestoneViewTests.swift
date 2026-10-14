@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalSpecimenMilestone("code-429", title: "title-545")
        let view = Labs.toSeasonalSpecimenMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalSpecimenMilestoneViews([item, item]).count == 2)
    }
}
