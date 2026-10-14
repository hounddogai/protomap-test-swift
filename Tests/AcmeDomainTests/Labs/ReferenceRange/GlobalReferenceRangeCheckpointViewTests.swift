@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalReferenceRangeCheckpoint("code-635", name: "name-669")
        let view = Labs.toGlobalReferenceRangeCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalReferenceRangeCheckpointViews([item, item]).count == 2)
    }
}
