@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultSlot("code-959", label: "label-858")
        let view = Labs.toResultSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultSlotViews([item, item]).count == 2)
    }
}
