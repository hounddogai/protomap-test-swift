@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveSpecimenSnapshot("code-770", title: "title-281")
        let view = Labs.toAdaptiveSpecimenSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveSpecimenSnapshotViews([item, item]).count == 2)
    }
}
