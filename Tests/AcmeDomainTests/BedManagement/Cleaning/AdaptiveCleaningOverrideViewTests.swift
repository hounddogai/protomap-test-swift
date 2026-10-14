@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveCleaningOverride("code-288", title: "title-155")
        let view = BedManagement.toAdaptiveCleaningOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveCleaningOverrideViews([item, item]).count == 2)
    }
}
