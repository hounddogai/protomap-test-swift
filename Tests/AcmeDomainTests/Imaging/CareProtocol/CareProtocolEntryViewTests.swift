@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolEntry("code-377", name: "name-80")
        let view = Imaging.toCareProtocolEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolEntryViews([item, item]).count == 2)
    }
}
