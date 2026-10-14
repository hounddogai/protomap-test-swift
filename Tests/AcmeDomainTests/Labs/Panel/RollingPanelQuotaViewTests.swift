@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingPanelQuota("code-262", title: "title-463")
        let view = Labs.toRollingPanelQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingPanelQuotaViews([item, item]).count == 2)
    }
}
