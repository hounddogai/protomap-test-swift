@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventorySchedule("code-91", label: "label-479")
        let view = Pharmacy.toInventoryScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryScheduleViews([item, item]).count == 2)
    }
}
