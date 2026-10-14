@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictBedBoardCycle("code-68", name: "name-324")
        let view = BedManagement.toStrictBedBoardCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictBedBoardCycleViews([item, item]).count == 2)
    }
}
