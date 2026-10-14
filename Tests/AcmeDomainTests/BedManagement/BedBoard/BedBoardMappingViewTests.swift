@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardMapping("code-575", label: "label-935")
        let view = BedManagement.toBedBoardMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardMappingViews([item, item]).count == 2)
    }
}
