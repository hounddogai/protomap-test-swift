@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualDischargePlanProfile("code-948", title: "title-94")
        let view = BedManagement.toManualDischargePlanProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualDischargePlanProfileViews([item, item]).count == 2)
    }
}
