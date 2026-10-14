@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardBatch("code-926", title: "title-957")
        let view = BedManagement.toBedBoardBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardBatchViews([item, item]).count == 2)
    }
}
