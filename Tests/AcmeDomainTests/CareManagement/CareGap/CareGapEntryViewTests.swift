@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapEntry("code-453", name: "name-369")
        let view = CareManagement.toCareGapEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapEntryViews([item, item]).count == 2)
    }
}
