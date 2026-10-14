@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        let view = Labs.toSpecimenCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenCheckpointViews([item, item]).count == 2)
    }
}
