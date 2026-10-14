@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveReferenceRangeMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        let view = Labs.toAdaptiveReferenceRangeMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveReferenceRangeMilestoneViews([item, item]).count == 2)
    }
}
