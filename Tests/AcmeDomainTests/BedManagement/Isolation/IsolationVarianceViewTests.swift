@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationVariance("code-991", title: "title-732")
        let view = BedManagement.toIsolationVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationVarianceViews([item, item]).count == 2)
    }
}
