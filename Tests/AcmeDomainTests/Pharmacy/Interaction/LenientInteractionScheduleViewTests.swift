@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInteractionSchedule("code-388", title: "title-181")
        let view = Pharmacy.toLenientInteractionScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInteractionScheduleViews([item, item]).count == 2)
    }
}
