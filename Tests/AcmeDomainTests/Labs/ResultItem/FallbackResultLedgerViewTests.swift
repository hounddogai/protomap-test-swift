@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackResultLedger("code-477", name: "name-126")
        let view = Labs.toFallbackResultLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackResultLedgerViews([item, item]).count == 2)
    }
}
