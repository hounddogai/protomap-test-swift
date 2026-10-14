@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingStudyEntry("code-604", name: "name-637")
        let view = Imaging.toRollingStudyEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingStudyEntryViews([item, item]).count == 2)
    }
}
