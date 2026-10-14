@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolCheckpoint("code-808", title: "title-569")
        let view = Imaging.toCareProtocolCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolCheckpointViews([item, item]).count == 2)
    }
}
