@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        let view = Labs.toSeasonalAccessionAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalAccessionAgreementViews([item, item]).count == 2)
    }
}
