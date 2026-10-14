@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalResultSlot("code-823", name: "name-939")
        let view = Labs.toGlobalResultSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalResultSlotViews([item, item]).count == 2)
    }
}
