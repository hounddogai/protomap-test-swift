@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittancePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittancePlan("code-396", title: "title-632")
        let view = RevenueCycle.toRemittancePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittancePlanViews([item, item]).count == 2)
    }
}
