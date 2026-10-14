@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFormularyCheckpoint("code-542", name: "name-405")
        let view = Pharmacy.toFormularyCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFormularyCheckpointViews([item, item]).count == 2)
    }
}
