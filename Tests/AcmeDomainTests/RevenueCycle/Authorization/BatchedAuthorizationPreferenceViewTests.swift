@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedAuthorizationPreference("code-601", title: "title-932")
        let view = RevenueCycle.toBatchedAuthorizationPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedAuthorizationPreferenceViews([item, item]).count == 2)
    }
}
