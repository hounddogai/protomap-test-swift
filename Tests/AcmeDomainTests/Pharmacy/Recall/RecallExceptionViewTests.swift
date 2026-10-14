@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallException("code-737", name: "name-769")
        let view = Pharmacy.toRecallExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallExceptionViews([item, item]).count == 2)
    }
}
