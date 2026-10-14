@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureAllocation("code-651", label: "label-772")
        let view = Consent.toDisclosureAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureAllocationViews([item, item]).count == 2)
    }
}
