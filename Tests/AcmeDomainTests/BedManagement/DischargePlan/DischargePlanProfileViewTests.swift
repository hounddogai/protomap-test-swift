@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDischargePlanProfile("code-473", title: "title-847")
        let view = BedManagement.toDischargePlanProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDischargePlanProfileViews([item, item]).count == 2)
    }
}
