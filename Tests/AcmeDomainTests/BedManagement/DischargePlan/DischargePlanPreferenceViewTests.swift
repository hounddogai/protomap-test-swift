@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDischargePlanPreference("code-660", name: "name-922")
        let view = BedManagement.toDischargePlanPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDischargePlanPreferenceViews([item, item]).count == 2)
    }
}
