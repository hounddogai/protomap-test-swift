@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        let view = Pharmacy.toRollingInventoryScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingInventoryScheduleViews([item, item]).count == 2)
    }
}
