@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyCensusDraft("code-817", label: "label-298")
        let view = BedManagement.toLegacyCensusDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyCensusDraftViews([item, item]).count == 2)
    }
}
