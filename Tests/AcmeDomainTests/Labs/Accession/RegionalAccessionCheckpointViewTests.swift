@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalAccessionCheckpoint("code-79", name: "name-908")
        let view = Labs.toRegionalAccessionCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalAccessionCheckpointViews([item, item]).count == 2)
    }
}
