@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedReferenceRangeAgreement("code-748", name: "name-913")
        let view = Labs.toCappedReferenceRangeAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedReferenceRangeAgreementViews([item, item]).count == 2)
    }
}
