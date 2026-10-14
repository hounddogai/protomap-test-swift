@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultDispenseException("code-762", name: "name-648")
        let view = Pharmacy.toDefaultDispenseExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultDispenseExceptionViews([item, item]).count == 2)
    }
}
