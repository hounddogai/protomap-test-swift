@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionCheckpoint("code-161", name: "name-710")
        let view = Pharmacy.toInteractionCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionCheckpointViews([item, item]).count == 2)
    }
}
