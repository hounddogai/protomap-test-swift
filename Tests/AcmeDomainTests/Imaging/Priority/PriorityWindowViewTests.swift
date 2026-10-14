@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityWindow("code-586", name: "name-45")
        let view = Imaging.toPriorityWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityWindowViews([item, item]).count == 2)
    }
}
