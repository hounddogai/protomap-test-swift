@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormAllocation("code-69", title: "title-886")
        let view = Consent.toConsentFormAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormAllocationViews([item, item]).count == 2)
    }
}
