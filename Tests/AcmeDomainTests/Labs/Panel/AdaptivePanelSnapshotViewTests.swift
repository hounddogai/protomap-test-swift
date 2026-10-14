@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptivePanelSnapshot("code-155", label: "label-152")
        let view = Labs.toAdaptivePanelSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptivePanelSnapshotViews([item, item]).count == 2)
    }
}
