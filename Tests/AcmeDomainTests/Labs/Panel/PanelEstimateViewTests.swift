@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        let view = Labs.toPanelEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelEstimateViews([item, item]).count == 2)
    }
}
