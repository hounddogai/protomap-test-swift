@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAuthorizationRecord("code-477", name: "name-524")
        let view = RevenueCycle.toAuthorizationRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAuthorizationRecordViews([item, item]).count == 2)
    }
}
