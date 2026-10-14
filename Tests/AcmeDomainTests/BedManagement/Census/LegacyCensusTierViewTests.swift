@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        let view = BedManagement.toLegacyCensusTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyCensusTierViews([item, item]).count == 2)
    }
}
