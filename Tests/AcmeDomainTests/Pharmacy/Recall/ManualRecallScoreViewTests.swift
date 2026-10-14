@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualRecallScore("code-514", title: "title-225")
        let view = Pharmacy.toManualRecallScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualRecallScoreViews([item, item]).count == 2)
    }
}
