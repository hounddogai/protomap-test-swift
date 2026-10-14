@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        let view = Staffing.toLenientCredentialCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientCredentialCheckpointViews([item, item]).count == 2)
    }
}
