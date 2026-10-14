@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedProxySummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWeightedProxySummary("code-103", name: "name-638")
        let view = Consent.toWeightedProxySummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWeightedProxySummaryViews([item, item]).count == 2)
    }
}
