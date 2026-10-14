@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackCourierSlot("code-121", name: "name-266")
        let view = Labs.toFallbackCourierSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackCourierSlotViews([item, item]).count == 2)
    }
}
