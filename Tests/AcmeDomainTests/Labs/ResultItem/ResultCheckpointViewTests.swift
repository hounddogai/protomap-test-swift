@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultCheckpoint("code-146", name: "name-395")
        let view = Labs.toResultCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultCheckpointViews([item, item]).count == 2)
    }
}
