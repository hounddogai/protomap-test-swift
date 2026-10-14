@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        let view = Labs.toCourierLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierLedgerViews([item, item]).count == 2)
    }
}
