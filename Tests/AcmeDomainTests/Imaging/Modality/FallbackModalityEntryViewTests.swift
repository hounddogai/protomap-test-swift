@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackModalityEntry("code-716", name: "name-777")
        let view = Imaging.toFallbackModalityEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackModalityEntryViews([item, item]).count == 2)
    }
}
