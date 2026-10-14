@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalCourierMilestone("code-597", label: "label-270")
        let view = Labs.toGlobalCourierMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalCourierMilestoneViews([item, item]).count == 2)
    }
}
