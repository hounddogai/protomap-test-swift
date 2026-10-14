@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseSnapshot("code-318", name: "name-817")
        let view = Pharmacy.toDispenseSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseSnapshotViews([item, item]).count == 2)
    }
}
