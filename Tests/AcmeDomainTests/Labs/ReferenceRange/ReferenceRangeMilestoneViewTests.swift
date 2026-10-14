@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeMilestone("code-339", label: "label-479")
        let view = Labs.toReferenceRangeMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeMilestoneViews([item, item]).count == 2)
    }
}
