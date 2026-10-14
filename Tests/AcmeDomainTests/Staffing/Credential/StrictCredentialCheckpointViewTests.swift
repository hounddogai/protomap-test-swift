@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictCredentialCheckpoint("code-197", name: "name-853")
        let view = Staffing.toStrictCredentialCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictCredentialCheckpointViews([item, item]).count == 2)
    }
}
