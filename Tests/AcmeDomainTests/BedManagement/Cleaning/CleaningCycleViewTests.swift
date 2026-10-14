@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningCycle("code-185", name: "name-292")
        let view = BedManagement.toCleaningCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningCycleViews([item, item]).count == 2)
    }
}
