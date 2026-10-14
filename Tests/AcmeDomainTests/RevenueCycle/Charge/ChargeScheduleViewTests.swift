@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeSchedule("code-591", name: "name-854")
        let view = RevenueCycle.toChargeScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeScheduleViews([item, item]).count == 2)
    }
}
