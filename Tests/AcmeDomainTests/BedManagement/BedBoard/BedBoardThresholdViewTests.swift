@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardThreshold("code-874", title: "title-928")
        let view = BedManagement.toBedBoardThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardThresholdViews([item, item]).count == 2)
    }
}
