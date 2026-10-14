@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferPreference("code-681", title: "title-416")
        let view = BedManagement.toTransferPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferPreferenceViews([item, item]).count == 2)
    }
}
