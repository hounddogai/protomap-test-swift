@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledAccessionMilestone("code-527", label: "label-358")
        let view = Labs.toScheduledAccessionMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledAccessionMilestoneViews([item, item]).count == 2)
    }
}
