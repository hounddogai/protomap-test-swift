@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientIsolationTemplate("code-605", title: "title-589")
        let view = BedManagement.toLenientIsolationTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientIsolationTemplateViews([item, item]).count == 2)
    }
}
