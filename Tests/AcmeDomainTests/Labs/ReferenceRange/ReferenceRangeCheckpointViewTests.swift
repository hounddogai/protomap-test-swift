@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeCheckpoint("code-483", name: "name-419")
        let view = Labs.toReferenceRangeCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeCheckpointViews([item, item]).count == 2)
    }
}
