@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedRecallProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedRecallProfile("code-583", label: "label-317")
        let view = Pharmacy.toBatchedRecallProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedRecallProfileViews([item, item]).count == 2)
    }
}
