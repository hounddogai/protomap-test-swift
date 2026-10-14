@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalResultMilestone("code-261", name: "name-164")
        let view = Labs.toSeasonalResultMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalResultMilestoneViews([item, item]).count == 2)
    }
}
