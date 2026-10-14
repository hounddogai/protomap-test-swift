@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultMilestone("code-603", name: "name-319")
        let view = Labs.toResultMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultMilestoneViews([item, item]).count == 2)
    }
}
