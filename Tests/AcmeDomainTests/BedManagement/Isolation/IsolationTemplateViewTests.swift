@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationTemplate("code-491", label: "label-566")
        let view = BedManagement.toIsolationTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationTemplateViews([item, item]).count == 2)
    }
}
