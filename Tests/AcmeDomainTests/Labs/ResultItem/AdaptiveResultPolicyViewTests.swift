@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveResultPolicy("code-522", label: "label-464")
        let view = Labs.toAdaptiveResultPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveResultPolicyViews([item, item]).count == 2)
    }
}
