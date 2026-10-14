@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalPanelPolicy("code-601", name: "name-582")
        let view = Labs.toSeasonalPanelPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalPanelPolicyViews([item, item]).count == 2)
    }
}
