@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        let view = Imaging.toManualPriorityEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualPriorityEntryViews([item, item]).count == 2)
    }
}
