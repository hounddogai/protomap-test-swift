@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionQuota("code-11", name: "name-491")
        let view = Labs.toAccessionQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionQuotaViews([item, item]).count == 2)
    }
}
