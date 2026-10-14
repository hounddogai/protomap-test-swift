@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseBatch("code-125", title: "title-881")
        let view = Pharmacy.toDispenseBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseBatchViews([item, item]).count == 2)
    }
}
