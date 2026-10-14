@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackCleaningTemplate("code-189", name: "name-289")
        let view = BedManagement.toFallbackCleaningTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackCleaningTemplateViews([item, item]).count == 2)
    }
}
