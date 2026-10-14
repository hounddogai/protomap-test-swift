@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedResultCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedResultCheckpoint("code-178", title: "title-649")
        let view = Labs.toBatchedResultCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedResultCheckpointViews([item, item]).count == 2)
    }
}
