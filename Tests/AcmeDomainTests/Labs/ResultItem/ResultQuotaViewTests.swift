@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultQuota("code-32", label: "label-594")
        let view = Labs.toResultQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultQuotaViews([item, item]).count == 2)
    }
}
