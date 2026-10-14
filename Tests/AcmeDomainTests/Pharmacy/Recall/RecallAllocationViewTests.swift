@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallAllocation("code-836", title: "title-831")
        let view = Pharmacy.toRecallAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallAllocationViews([item, item]).count == 2)
    }
}
