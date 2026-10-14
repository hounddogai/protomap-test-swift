@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultLanguageAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDefaultLanguageAllocation("code-958", name: "name-71")
        let view = Consent.toDefaultLanguageAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDefaultLanguageAllocationViews([item, item]).count == 2)
    }
}
