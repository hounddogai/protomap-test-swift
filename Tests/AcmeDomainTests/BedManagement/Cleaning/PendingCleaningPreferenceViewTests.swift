@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingCleaningPreference("code-285", label: "label-373")
        let view = BedManagement.toPendingCleaningPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingCleaningPreferenceViews([item, item]).count == 2)
    }
}
