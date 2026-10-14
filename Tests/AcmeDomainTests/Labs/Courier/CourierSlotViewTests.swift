@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        let view = Labs.toCourierSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierSlotViews([item, item]).count == 2)
    }
}
