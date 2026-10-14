@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualCredentialMapping("code-887", name: "name-814")
        let view = Staffing.toManualCredentialMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualCredentialMappingViews([item, item]).count == 2)
    }
}
