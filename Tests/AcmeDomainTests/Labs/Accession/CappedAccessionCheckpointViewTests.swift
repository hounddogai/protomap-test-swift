@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedAccessionCheckpoint("code-696", name: "name-199")
        let view = Labs.toCappedAccessionCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedAccessionCheckpointViews([item, item]).count == 2)
    }
}
