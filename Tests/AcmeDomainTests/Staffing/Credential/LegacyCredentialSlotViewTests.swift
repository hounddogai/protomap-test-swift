@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyCredentialSlot("code-990", label: "label-817")
        let view = Staffing.toLegacyCredentialSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyCredentialSlotViews([item, item]).count == 2)
    }
}
