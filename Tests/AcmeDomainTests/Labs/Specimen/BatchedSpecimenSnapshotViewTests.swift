@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        let view = Labs.toBatchedSpecimenSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedSpecimenSnapshotViews([item, item]).count == 2)
    }
}
