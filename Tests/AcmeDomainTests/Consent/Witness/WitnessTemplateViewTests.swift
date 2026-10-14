@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessTemplate("code-190", title: "title-954")
        let view = Consent.toWitnessTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessTemplateViews([item, item]).count == 2)
    }
}
