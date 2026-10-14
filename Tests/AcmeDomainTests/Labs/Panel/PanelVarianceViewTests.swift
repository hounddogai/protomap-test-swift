@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        let view = Labs.toPanelVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelVarianceViews([item, item]).count == 2)
    }
}
