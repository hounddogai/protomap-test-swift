@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLegacyCareProtocolEntry("code-931", label: "label-806")
        let view = Imaging.toLegacyCareProtocolEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLegacyCareProtocolEntryViews([item, item]).count == 2)
    }
}
