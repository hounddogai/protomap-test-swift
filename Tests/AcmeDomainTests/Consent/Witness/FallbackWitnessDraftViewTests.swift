@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackWitnessDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        let view = Consent.toFallbackWitnessDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackWitnessDraftViews([item, item]).count == 2)
    }
}
