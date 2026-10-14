@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapWindow("code-80", name: "name-278")
        let view = CareManagement.toCareGapWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapWindowViews([item, item]).count == 2)
    }
}
