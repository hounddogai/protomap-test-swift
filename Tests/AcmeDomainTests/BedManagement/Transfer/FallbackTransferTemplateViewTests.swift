@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackTransferTemplate("code-243", title: "title-263")
        let view = BedManagement.toFallbackTransferTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackTransferTemplateViews([item, item]).count == 2)
    }
}
