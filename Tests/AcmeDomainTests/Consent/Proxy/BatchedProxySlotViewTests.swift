@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedProxySlot("code-657", label: "label-419")
        let view = Consent.toBatchedProxySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedProxySlotViews([item, item]).count == 2)
    }
}
