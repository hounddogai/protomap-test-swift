@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        let view = Pharmacy.toCappedDispenseCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedDispenseCheckpointViews([item, item]).count == 2)
    }
}
