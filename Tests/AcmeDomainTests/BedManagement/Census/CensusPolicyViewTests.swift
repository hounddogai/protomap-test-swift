@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusPolicy("code-323", name: "name-447")
        let view = BedManagement.toCensusPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusPolicyViews([item, item]).count == 2)
    }
}
