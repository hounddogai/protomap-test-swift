@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingAccessionCheckpoint("code-1", title: "title-861")
        let view = Labs.toRollingAccessionCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingAccessionCheckpointViews([item, item]).count == 2)
    }
}
