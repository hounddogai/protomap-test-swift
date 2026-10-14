@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierMilestone("code-210", label: "label-642")
        let view = Labs.toCourierMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierMilestoneViews([item, item]).count == 2)
    }
}
