@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledCleaningException("code-35", name: "name-111")
        let view = BedManagement.toScheduledCleaningExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledCleaningExceptionViews([item, item]).count == 2)
    }
}
