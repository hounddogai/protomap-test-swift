@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingWitnessEntry("code-374", name: "name-653")
        let view = Consent.toRollingWitnessEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingWitnessEntryViews([item, item]).count == 2)
    }
}
