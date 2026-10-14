@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionException("code-853", label: "label-572")
        let view = Pharmacy.toInteractionExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionExceptionViews([item, item]).count == 2)
    }
}
