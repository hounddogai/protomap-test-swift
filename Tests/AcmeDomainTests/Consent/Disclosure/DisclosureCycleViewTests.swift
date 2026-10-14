@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureCycle("code-462", title: "title-706")
        let view = Consent.toDisclosureCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureCycleViews([item, item]).count == 2)
    }
}
