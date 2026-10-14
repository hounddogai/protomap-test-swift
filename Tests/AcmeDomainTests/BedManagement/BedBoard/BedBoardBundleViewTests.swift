@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardBundle("code-566", label: "label-376")
        let view = BedManagement.toBedBoardBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardBundleViews([item, item]).count == 2)
    }
}
