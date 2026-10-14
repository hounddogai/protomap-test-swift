@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyAllocation("code-92", name: "name-649")
        let view = Consent.toProxyAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyAllocationViews([item, item]).count == 2)
    }
}
