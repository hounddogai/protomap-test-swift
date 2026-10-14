@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveStatementProfile("code-154", label: "label-191")
        let view = RevenueCycle.toAdaptiveStatementProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveStatementProfileViews([item, item]).count == 2)
    }
}
