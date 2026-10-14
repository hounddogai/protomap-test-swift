@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        let view = BedManagement.toTieredIsolationTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredIsolationTemplateViews([item, item]).count == 2)
    }
}
