@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        let view = Pharmacy.toWeightedRecallDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedRecallDraftViews([item, item]).count == 2)
    }
}
