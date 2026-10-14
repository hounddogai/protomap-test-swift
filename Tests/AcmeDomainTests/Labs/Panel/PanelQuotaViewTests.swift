@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        let view = Labs.toPanelQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelQuotaViews([item, item]).count == 2)
    }
}
