@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryResultSlot("code-566", title: "title-262")
        let view = Labs.toPrimaryResultSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryResultSlotViews([item, item]).count == 2)
    }
}
