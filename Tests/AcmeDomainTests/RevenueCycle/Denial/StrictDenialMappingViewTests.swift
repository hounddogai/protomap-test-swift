@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictDenialMapping("code-432", name: "name-28")
        let view = RevenueCycle.toStrictDenialMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictDenialMappingViews([item, item]).count == 2)
    }
}
