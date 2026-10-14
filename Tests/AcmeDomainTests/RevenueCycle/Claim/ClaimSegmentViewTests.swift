@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimSegment("code-915", label: "label-232")
        let view = RevenueCycle.toClaimSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimSegmentViews([item, item]).count == 2)
    }
}
