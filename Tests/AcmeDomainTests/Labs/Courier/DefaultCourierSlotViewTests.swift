@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultCourierSlot("code-335", name: "name-681")
        let view = Labs.toDefaultCourierSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultCourierSlotViews([item, item]).count == 2)
    }
}
