@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalCredentialTarget("code-692", name: "name-69")
        let view = Staffing.toGlobalCredentialTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalCredentialTargetViews([item, item]).count == 2)
    }
}
