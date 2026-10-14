@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierAgreement("code-460", name: "name-492")
        let view = Labs.toCourierAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierAgreementViews([item, item]).count == 2)
    }
}
