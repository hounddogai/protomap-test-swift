@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityEntry("code-699", name: "name-913")
        let view = Imaging.toPriorityEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityEntryViews([item, item]).count == 2)
    }
}
