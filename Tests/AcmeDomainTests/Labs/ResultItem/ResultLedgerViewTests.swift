@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultLedger("code-7", name: "name-119")
        let view = Labs.toResultLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultLedgerViews([item, item]).count == 2)
    }
}
