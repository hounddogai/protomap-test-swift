@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenMilestone("code-151", label: "label-707")
        let view = Labs.toSpecimenMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenMilestoneViews([item, item]).count == 2)
    }
}
