@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelBatch("code-235", label: "label-929")
        let view = Labs.toPanelBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelBatchViews([item, item]).count == 2)
    }
}
