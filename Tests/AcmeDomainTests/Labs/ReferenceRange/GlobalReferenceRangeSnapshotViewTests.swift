@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalReferenceRangeSnapshot("code-727", label: "label-70")
        let view = Labs.toGlobalReferenceRangeSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalReferenceRangeSnapshotViews([item, item]).count == 2)
    }
}
