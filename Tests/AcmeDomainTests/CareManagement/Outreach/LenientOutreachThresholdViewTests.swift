@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientOutreachThreshold("code-634", name: "name-961")
        let view = CareManagement.toLenientOutreachThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientOutreachThresholdViews([item, item]).count == 2)
    }
}
