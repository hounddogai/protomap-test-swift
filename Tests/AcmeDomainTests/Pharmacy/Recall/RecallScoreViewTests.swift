@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallScore("code-220", label: "label-696")
        let view = Pharmacy.toRecallScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallScoreViews([item, item]).count == 2)
    }
}
