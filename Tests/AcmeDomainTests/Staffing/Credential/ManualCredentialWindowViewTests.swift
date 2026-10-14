@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualCredentialWindow("code-60", name: "name-156")
        let view = Staffing.toManualCredentialWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualCredentialWindowViews([item, item]).count == 2)
    }
}
