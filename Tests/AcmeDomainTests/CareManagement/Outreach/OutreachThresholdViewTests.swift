@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachThreshold("code-30", title: "title-831")
        let view = CareManagement.toOutreachThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachThresholdViews([item, item]).count == 2)
    }
}
