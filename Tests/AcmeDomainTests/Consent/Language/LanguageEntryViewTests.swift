@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageEntry("code-841", label: "label-528")
        let view = Consent.toLanguageEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageEntryViews([item, item]).count == 2)
    }
}
