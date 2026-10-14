@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        let view = Consent.toWeightedWitnessEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWeightedWitnessEntryViews([item, item]).count == 2)
    }
}
