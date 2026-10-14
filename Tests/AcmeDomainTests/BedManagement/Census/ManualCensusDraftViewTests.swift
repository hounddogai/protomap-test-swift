@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualCensusDraft("code-948", label: "label-111")
        let view = BedManagement.toManualCensusDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualCensusDraftViews([item, item]).count == 2)
    }
}
