@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalClaimScore("code-512", name: "name-690")
        let view = RevenueCycle.toGlobalClaimScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalClaimScoreViews([item, item]).count == 2)
    }
}
