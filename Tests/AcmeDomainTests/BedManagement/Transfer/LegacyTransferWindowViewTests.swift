@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyTransferWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyTransferWindow("code-769", name: "name-391")
        let view = BedManagement.toLegacyTransferWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyTransferWindowViews([item, item]).count == 2)
    }
}
