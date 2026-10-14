@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapException("code-500", title: "title-694")
        let view = CareManagement.toCareGapExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapExceptionViews([item, item]).count == 2)
    }
}
