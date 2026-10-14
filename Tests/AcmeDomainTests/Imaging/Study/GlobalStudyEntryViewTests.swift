@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalStudyEntry("code-853", label: "label-893")
        let view = Imaging.toGlobalStudyEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalStudyEntryViews([item, item]).count == 2)
    }
}
