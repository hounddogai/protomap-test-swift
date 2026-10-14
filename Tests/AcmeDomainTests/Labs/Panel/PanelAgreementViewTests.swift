@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelAgreement("code-446", title: "title-279")
        let view = Labs.toPanelAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelAgreementViews([item, item]).count == 2)
    }
}
