@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        let view = BedManagement.toLenientDischargePlanWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientDischargePlanWindowViews([item, item]).count == 2)
    }
}
